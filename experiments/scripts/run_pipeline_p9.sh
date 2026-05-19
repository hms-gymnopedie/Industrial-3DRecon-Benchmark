#!/usr/bin/env bash
# =============================================================================
# run_pipeline_p9.sh — P9 (H-Best) end-to-end pipeline
#   Stage 1:   M7 MASt3R-SLAM (deep-prior visual SLAM, pose+native pointmap)
#   Stage 2:   Adapter (MASt3R-SLAM native → COLMAP text format, OPENCV)
#   Stage 2.5: COLMAP image_undistorter (OPENCV → PINHOLE + undistorted images)
#   Stage 3:   M9 2DGS train on undistorted PINHOLE + native TSDF mesh
#
# NOTE: 2DGS dataset_readers.py 는 OPENCV camera model 거부 (3DGS fork 의 limit).
# Stage 2.5 의 undistortion 이 필수 (m1_colmap 컨테이너 재활용).
#
# Pre-registered hypothesis: H-Best — learned pose backbone + planar primitives
# 산업현장 textureless / reflective / dynamic / 저조도 도메인에서 최상위 성능 예상.
#
# Usage:
#   run_pipeline_p9.sh [--site I-1] [--run run-01] [--gpu-pose 0] [--gpu-rep 1] \
#                     [--data-root ./data] [--weights ./weights] \
#                     [--iterations 30000] \
#                     [--skip-pose|--skip-adapt|--skip-undistort|--skip-rep]
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------
SITE="I-1"
RUN="run-01"
GPU_POSE=0
GPU_REP=1
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DATA_ROOT="${REPO_ROOT}/data"
WEIGHTS_DIR="${REPO_ROOT}/experiments/weights"
ITERATIONS=30000
SKIP_POSE=0
SKIP_ADAPT=0
SKIP_UNDISTORT=0
SKIP_REP=0
PIPELINE_ID="P9"
M1_IMAGE="ars/m1_colmap:3.9.1"
M7_IMAGE="ars/m7_mast3r_slam:latest"
M9_IMAGE="ars/m9_2dgs:latest"
MAST3R_CKPT="MASt3R_ViTLarge_BaseDecoder_512_catmlpdpt_metric.pth"

# ---------------------------------------------------------------
# Arg parsing
# ---------------------------------------------------------------
while [ $# -gt 0 ]; do
    case "$1" in
        --site)        SITE="$2"; shift 2 ;;
        --run)         RUN="$2"; shift 2 ;;
        --gpu-pose)    GPU_POSE="$2"; shift 2 ;;
        --gpu-rep)     GPU_REP="$2"; shift 2 ;;
        --data-root)   DATA_ROOT="$2"; shift 2 ;;
        --weights)     WEIGHTS_DIR="$2"; shift 2 ;;
        --iterations)  ITERATIONS="$2"; shift 2 ;;
        --skip-pose)      SKIP_POSE=1; shift ;;
        --skip-adapt)     SKIP_ADAPT=1; shift ;;
        --skip-undistort) SKIP_UNDISTORT=1; shift ;;
        --skip-rep)       SKIP_REP=1; shift ;;
        -h|--help)     sed -n '2,17p' "$0"; exit 0 ;;
        *) echo "Unknown arg: $1"; exit 2 ;;
    esac
done

# ---------------------------------------------------------------
# Path layout (data/README.md §7 규약)
# ---------------------------------------------------------------
SITE_DIR="${DATA_ROOT}/sites/${SITE}"
FRAMES_DIR="${SITE_DIR}/runs/${RUN}/frames"
INTRINSICS_FILE="${SITE_DIR}/calib/intrinsics.json"
OUT_DIR="${DATA_ROOT}/outputs/${PIPELINE_ID}/${SITE}/${RUN}"
POSE_NATIVE_DIR="${OUT_DIR}/pose_native"
POSE_DIR="${OUT_DIR}/pose"
UNDISTORT_DIR="${OUT_DIR}/pose_undistorted"
RECON_DIR="${OUT_DIR}/recon"
LOG_DIR="${OUT_DIR}/logs"
METRICS_FILE="${OUT_DIR}/metrics.json"

mkdir -p "${POSE_NATIVE_DIR}" "${POSE_DIR}/sparse/0" "${UNDISTORT_DIR}" "${RECON_DIR}" "${LOG_DIR}"

# ---------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------
echo "================================================================"
echo "  ARS Pipeline ${PIPELINE_ID} (H-Best) — site=${SITE} run=${RUN}"
echo "================================================================"
echo "  data_root:     ${DATA_ROOT}"
echo "  weights_dir:   ${WEIGHTS_DIR}"
echo "  frames_dir:    ${FRAMES_DIR}"
echo "  intrinsics:    ${INTRINSICS_FILE}"
echo "  out_dir:       ${OUT_DIR}"
echo "  gpu-pose:      ${GPU_POSE}  (M7 MASt3R-SLAM)"
echo "  gpu-rep:       ${GPU_REP}   (M9 2DGS)"
echo "  iterations:    ${ITERATIONS}"
echo "  skip pose/adapt/rep = ${SKIP_POSE}/${SKIP_ADAPT}/${SKIP_REP}"

if [ ! -d "${FRAMES_DIR}" ]; then
    echo "[FATAL] frames 디렉토리 없음: ${FRAMES_DIR}"
    exit 1
fi
if [ ! -f "${INTRINSICS_FILE}" ]; then
    echo "[FATAL] intrinsics JSON 없음: ${INTRINSICS_FILE}"
    echo "        data/README.md §4 schema 참조."
    exit 1
fi
if [ ! -f "${WEIGHTS_DIR}/${MAST3R_CKPT}" ]; then
    echo "[FATAL] MASt3R checkpoint 없음: ${WEIGHTS_DIR}/${MAST3R_CKPT}"
    echo "        bash experiments/scripts/download_weights.sh 먼저 실행."
    exit 1
fi
N_FRAMES=$(find "${FRAMES_DIR}" -maxdepth 1 -type f -name '*.png' | wc -l | tr -d ' ')
echo "  n_frames:      ${N_FRAMES}"

# ---------------------------------------------------------------
# Stage 1: M7 MASt3R-SLAM — deep-prior visual SLAM
# ---------------------------------------------------------------
T_POSE_START=$(date +%s)
if [ "${SKIP_POSE}" -eq 0 ]; then
    echo
    echo "----------------------------------------------------------------"
    echo "  Stage 1: M7 MASt3R-SLAM"
    echo "----------------------------------------------------------------"
    # NOTE: upstream MASt3R-SLAM의 정확한 entrypoint (main.py 위치/CLI flag)는
    # repo 검수 시점에 조정 필요. 본 호출은 표준 wrapper 가정.
    # PYTHONPATH override — Dockerfile 의 ENV 값이 잘못된 path (/opt/mast3r_slam/mast3r,
    # 존재 안 함) 를 가리키고 실제 mast3r 는 thirdparty/ 아래에 있음. 본 override 로
    # rebuild 없이 import 정상화. Next image rebuild 시 Dockerfile fix 도 반영됨.
    docker run --rm \
        --gpus "\"device=${GPU_POSE}\"" \
        --user "$(id -u):$(id -g)" \
        --entrypoint python \
        -e PYTHONPATH=/opt/mast3r_slam:/opt/mast3r_slam/thirdparty/mast3r:/opt/mast3r_slam/thirdparty/mast3r/dust3r:/opt/mast3r_slam/thirdparty/in3d:/opt/asmk \
        -v "${DATA_ROOT}:/data" \
        -v "${WEIGHTS_DIR}:/weights" \
        --name "ars-${PIPELINE_ID}-${SITE}-${RUN}-m7" \
        "${M7_IMAGE}" \
        /opt/mast3r_slam/main.py \
            --image_dir "/data/sites/${SITE}/runs/${RUN}/frames" \
            --output_dir "/data/outputs/${PIPELINE_ID}/${SITE}/${RUN}/pose_native" \
            --checkpoint "/weights/${MAST3R_CKPT}" \
            --intrinsics "/data/sites/${SITE}/calib/intrinsics.json" \
            --device cuda:0 \
            2>&1 | tee "${LOG_DIR}/m7_mast3r_slam.log"
else
    echo "[skip] Stage 1 (M7 MASt3R-SLAM) — --skip-pose"
fi
T_POSE_END=$(date +%s)
T_POSE=$(( T_POSE_END - T_POSE_START ))

# ---------------------------------------------------------------
# Stage 2: Adapter — MASt3R-SLAM native → COLMAP-format
# ---------------------------------------------------------------
T_ADAPT_START=$(date +%s)
if [ "${SKIP_ADAPT}" -eq 0 ]; then
    echo
    echo "----------------------------------------------------------------"
    echo "  Stage 2: M7 → COLMAP-format adapter"
    echo "----------------------------------------------------------------"
    # Adapter는 m7 컨테이너 내부에서 실행 (numpy/scipy/plyfile 이미 포함).
    # 경로 추정: pose_native/trajectory.txt + (선택) pose_native/points.ply
    # 정확한 native 파일명은 upstream MASt3R-SLAM 출력 검수 시 보정 (adapters/README.md §1 참조).
    TRAJECTORY_PATH="/data/outputs/${PIPELINE_ID}/${SITE}/${RUN}/pose_native/trajectory.txt"
    PLY_PATH="/data/outputs/${PIPELINE_ID}/${SITE}/${RUN}/pose_native/points.ply"

    docker run --rm \
        --user "$(id -u):$(id -g)" \
        --entrypoint python \
        -e PYTHONPATH=/opt/mast3r_slam:/opt/mast3r_slam/thirdparty/mast3r:/opt/mast3r_slam/thirdparty/mast3r/dust3r:/opt/asmk \
        -v "${DATA_ROOT}:/data" \
        -v "${REPO_ROOT}/experiments/adapters:/adapters" \
        --name "ars-${PIPELINE_ID}-${SITE}-${RUN}-adapter" \
        "${M7_IMAGE}" \
        /adapters/mast3r_slam_to_colmap.py \
            --trajectory "${TRAJECTORY_PATH}" \
            --intrinsics "/data/sites/${SITE}/calib/intrinsics.json" \
            --frames-dir "/data/sites/${SITE}/runs/${RUN}/frames" \
            --pointcloud "${PLY_PATH}" \
            --output "/data/outputs/${PIPELINE_ID}/${SITE}/${RUN}/pose/sparse/0" \
            --max-points 100000 \
            2>&1 | tee "${LOG_DIR}/adapter.log"
else
    echo "[skip] Stage 2 (adapter) — --skip-adapt"
fi
T_ADAPT_END=$(date +%s)
T_ADAPT=$(( T_ADAPT_END - T_ADAPT_START ))

# Sanity check COLMAP-format output
if [ ! -f "${POSE_DIR}/sparse/0/cameras.txt" ] || [ ! -f "${POSE_DIR}/sparse/0/images.txt" ]; then
    echo "[FATAL] adapter 출력 누락: ${POSE_DIR}/sparse/0/{cameras,images}.txt"
    exit 3
fi

# ---------------------------------------------------------------
# Stage 2.5: COLMAP image_undistorter — OPENCV → PINHOLE
#   2DGS dataset_readers.py 가 OPENCV camera model 거부 (3DGS fork limit).
#   m1_colmap 컨테이너 재활용 (M7 컨테이너에 colmap binary 없음).
#
# IMPORTANT: COLMAP image_undistorter 는 sparse model 을 sparse/ 에
# 직접 출력 (sparse/0/ 아님). 2DGS dataset_readers 는 sparse/0/ 기대
# → post-process mv 로 sparse/*.bin → sparse/0/*.bin 재배치 필수.
#
# Idempotent: pose_undistorted/sparse/0/cameras.{bin,txt} 가 이미 있으면 skip.
# ---------------------------------------------------------------
T_UNDISTORT_START=$(date +%s)
UNDISTORT_DONE=0
if [ -f "${UNDISTORT_DIR}/sparse/0/cameras.bin" ] || [ -f "${UNDISTORT_DIR}/sparse/0/cameras.txt" ]; then
    echo
    echo "[skip] Stage 2.5 (image_undistorter) — undistorted output 이미 존재"
    UNDISTORT_DONE=1
fi
if [ "${SKIP_UNDISTORT}" -eq 0 ] && [ "${UNDISTORT_DONE}" -eq 0 ]; then
    echo
    echo "----------------------------------------------------------------"
    echo "  Stage 2.5: COLMAP image_undistorter (OPENCV → PINHOLE)"
    echo "----------------------------------------------------------------"
    docker run --rm \
        --gpus "\"device=${GPU_POSE}\"" \
        --user "$(id -u):$(id -g)" \
        --entrypoint colmap \
        -v "${DATA_ROOT}:/data" \
        --name "ars-${PIPELINE_ID}-${SITE}-${RUN}-undistort" \
        "${M1_IMAGE}" \
        image_undistorter \
            --image_path  "/data/sites/${SITE}/runs/${RUN}/frames" \
            --input_path  "/data/outputs/${PIPELINE_ID}/${SITE}/${RUN}/pose/sparse/0" \
            --output_path "/data/outputs/${PIPELINE_ID}/${SITE}/${RUN}/pose_undistorted" \
            --output_type COLMAP \
            2>&1 | tee "${LOG_DIR}/colmap_undistort.log"

    # Post-process: image_undistorter 의 sparse/ 출력을 sparse/0/ 로 재배치
    # (2DGS dataset_readers.py 의 source_path/sparse/0/ 기대와 매칭)
    if [ -f "${UNDISTORT_DIR}/sparse/cameras.bin" ] && [ ! -f "${UNDISTORT_DIR}/sparse/0/cameras.bin" ]; then
        echo "  [post-undistort] sparse/*.bin → sparse/0/*.bin 재배치"
        mkdir -p "${UNDISTORT_DIR}/sparse/0"
        mv "${UNDISTORT_DIR}/sparse"/*.bin "${UNDISTORT_DIR}/sparse/0/"
    fi
elif [ "${SKIP_UNDISTORT}" -eq 1 ]; then
    echo "[skip] Stage 2.5 (image_undistorter) — --skip-undistort"
fi
T_UNDISTORT_END=$(date +%s)
T_UNDISTORT=$(( T_UNDISTORT_END - T_UNDISTORT_START ))

# Sanity check undistorted output (2DGS 진입 전 필수 검증; sparse/0/ 경로로 검사)
if [ ! -f "${UNDISTORT_DIR}/sparse/0/cameras.bin" ] && [ ! -f "${UNDISTORT_DIR}/sparse/0/cameras.txt" ]; then
    echo "[FATAL] image_undistorter 출력 누락: ${UNDISTORT_DIR}/sparse/0/cameras.{bin,txt}"
    echo "        Stage 2.5 실패 또는 sparse/0/ 재배치 실패 — log 확인: ${LOG_DIR}/colmap_undistort.log"
    exit 4
fi

# ---------------------------------------------------------------
# Stage 3: M9 2DGS — planar-prior representation (on undistorted PINHOLE)
# ---------------------------------------------------------------
T_REP_START=$(date +%s)
if [ "${SKIP_REP}" -eq 0 ]; then
    echo
    echo "----------------------------------------------------------------"
    echo "  Stage 3: M9 2DGS train (${ITERATIONS} iter)"
    echo "----------------------------------------------------------------"
    # GPU 활용 우선 정책 (PAPER §3.6 F2; P1 과 동일 hyperparameter)
    docker run --rm \
        --gpus "\"device=${GPU_REP}\"" \
        --user "$(id -u):$(id -g)" \
        --entrypoint python \
        -v "${DATA_ROOT}:/data" \
        --name "ars-${PIPELINE_ID}-${SITE}-${RUN}-m9" \
        "${M9_IMAGE}" \
        /opt/two_dgs/train.py \
            --source_path "/data/outputs/${PIPELINE_ID}/${SITE}/${RUN}/pose_undistorted" \
            --model_path "/data/outputs/${PIPELINE_ID}/${SITE}/${RUN}/recon" \
            --iterations "${ITERATIONS}" \
            --resolution 2 \
            --data_device cuda \
            --eval \
            2>&1 | tee "${LOG_DIR}/m9_2dgs.log"

    # Native TSDF mesh extraction (2DGS feature)
    echo
    echo "  [extra] 2DGS native mesh extraction (TSDF fusion)"
    docker run --rm \
        --gpus "\"device=${GPU_REP}\"" \
        --user "$(id -u):$(id -g)" \
        --entrypoint python \
        -v "${DATA_ROOT}:/data" \
        --name "ars-${PIPELINE_ID}-${SITE}-${RUN}-m9-mesh" \
        "${M9_IMAGE}" \
        /opt/two_dgs/render.py \
            --model_path "/data/outputs/${PIPELINE_ID}/${SITE}/${RUN}/recon" \
            --skip_train --skip_test \
            --mesh_res 1024 \
            2>&1 | tee -a "${LOG_DIR}/m9_2dgs.log"
else
    echo "[skip] Stage 3 (M9 2DGS) — --skip-rep"
fi
T_REP_END=$(date +%s)
T_REP=$(( T_REP_END - T_REP_START ))

# ---------------------------------------------------------------
# Stage 3.5: M9 metrics.py — PSNR/SSIM/LPIPS 측정 → results.json
#   2DGS upstream 의 train.py 는 학습만 수행. PSNR/SSIM/LPIPS 는 metrics.py 가
#   별도로 계산. compute_metrics.py 가 results.json 을 읽어 metrics.json 에 합성.
#   Idempotent: results.json 이 이미 있으면 skip.
# ---------------------------------------------------------------
if [ "${SKIP_REP}" -eq 0 ]; then
    if [ -f "${RECON_DIR}/results.json" ]; then
        echo
        echo "[skip] Stage 3.5 (metrics.py) — results.json 이미 존재"
    else
        echo
        echo "----------------------------------------------------------------"
        echo "  Stage 3.5: M9 2DGS metrics.py (PSNR/SSIM/LPIPS)"
        echo "----------------------------------------------------------------"
        docker run --rm \
            --gpus "\"device=${GPU_REP}\"" \
            --user "$(id -u):$(id -g)" \
            --entrypoint python \
            -v "${DATA_ROOT}:/data" \
            --name "ars-${PIPELINE_ID}-${SITE}-${RUN}-m9-metrics" \
            "${M9_IMAGE}" \
            /opt/two_dgs/metrics.py \
                --model_paths "/data/outputs/${PIPELINE_ID}/${SITE}/${RUN}/recon" \
                2>&1 | tee -a "${LOG_DIR}/m9_2dgs.log"
    fi
fi

# ---------------------------------------------------------------
# Metrics aggregation
# ---------------------------------------------------------------
echo
echo "----------------------------------------------------------------"
echo "  Metrics aggregation"
echo "----------------------------------------------------------------"
# adapter time 에 image_undistorter (Stage 2.5) 도 합산 (별도 compute_metrics flag 없음)
T_ADAPT_TOTAL=$(( T_ADAPT + T_UNDISTORT ))
python3 "$(dirname "${BASH_SOURCE[0]}")/compute_metrics.py" \
    --pipeline "${PIPELINE_ID}" \
    --site "${SITE}" \
    --run "${RUN}" \
    --recon-dir "${RECON_DIR}" \
    --t-pose "${T_POSE}" \
    --t-rep "${T_REP}" \
    --t-adapter "${T_ADAPT_TOTAL}" \
    --output "${METRICS_FILE}"

# ---------------------------------------------------------------
# Summary
# ---------------------------------------------------------------
echo
echo "================================================================"
echo "  ${PIPELINE_ID} 완료 — site=${SITE} run=${RUN}"
echo "    pose      (Stage 1):    ${T_POSE}s"
echo "    adapter   (Stage 2):    ${T_ADAPT}s"
echo "    undistort (Stage 2.5):  ${T_UNDISTORT}s"
echo "    rep       (Stage 3):    ${T_REP}s"
echo "    output:                 ${OUT_DIR}"
echo "    metrics:                ${METRICS_FILE}"
echo "================================================================"
