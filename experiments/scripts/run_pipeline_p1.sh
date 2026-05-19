#!/usr/bin/env bash
# =============================================================================
# run_pipeline_p1.sh — P1 (H-Worst) end-to-end pipeline
#   Stage 1:   M1 COLMAP (SfM pose, OPENCV camera model)
#   Stage 1.5: COLMAP image_undistorter (OPENCV → PINHOLE + undistorted images)
#   Stage 2:   M8 3DGS train on undistorted PINHOLE images
#
# NOTE: 3DGS/2DGS dataset_readers.py 는 OPENCV camera model 거부 (PINHOLE /
# SIMPLE_PINHOLE 만 지원). 따라서 Stage 1.5 의 undistortion 이 필수.
#
# Pre-registered hypothesis: H-Worst — hand-crafted SfM + volumetric primitives
# 산업현장 textureless / reflective / dynamic 도메인에서 최하위 성능 예상.
#
# Usage:
#   run_pipeline_p1.sh [--site I-1] [--run run-01] [--gpu-pose 0] [--gpu-rep 1] \
#                     [--data-root ./data] [--iterations 30000] \
#                     [--skip-pose|--skip-undistort|--skip-rep]
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------
SITE="I-1"
RUN="run-01"
GPU_POSE=0
GPU_REP=1
DATA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/data"
ITERATIONS=30000
SKIP_POSE=0
SKIP_UNDISTORT=0
SKIP_REP=0
PIPELINE_ID="P1"
M1_IMAGE="ars/m1_colmap:3.9.1"
M8_IMAGE="ars/m8_3dgs:latest"

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
        --iterations)  ITERATIONS="$2"; shift 2 ;;
        --skip-pose)      SKIP_POSE=1; shift ;;
        --skip-undistort) SKIP_UNDISTORT=1; shift ;;
        --skip-rep)       SKIP_REP=1; shift ;;
        -h|--help)     sed -n '2,15p' "$0"; exit 0 ;;
        *) echo "Unknown arg: $1"; exit 2 ;;
    esac
done

# ---------------------------------------------------------------
# Path layout (data/README.md §7 규약)
# ---------------------------------------------------------------
SITE_DIR="${DATA_ROOT}/sites/${SITE}"
FRAMES_DIR="${SITE_DIR}/runs/${RUN}/frames"
OUT_DIR="${DATA_ROOT}/outputs/${PIPELINE_ID}/${SITE}/${RUN}"
POSE_DIR="${OUT_DIR}/pose"
UNDISTORT_DIR="${OUT_DIR}/pose_undistorted"
RECON_DIR="${OUT_DIR}/recon"
LOG_DIR="${OUT_DIR}/logs"
METRICS_FILE="${OUT_DIR}/metrics.json"

mkdir -p "${POSE_DIR}" "${UNDISTORT_DIR}" "${RECON_DIR}" "${LOG_DIR}"

# ---------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------
echo "================================================================"
echo "  ARS Pipeline ${PIPELINE_ID} (H-Worst) — site=${SITE} run=${RUN}"
echo "================================================================"
echo "  data_root:     ${DATA_ROOT}"
echo "  frames_dir:    ${FRAMES_DIR}"
echo "  out_dir:       ${OUT_DIR}"
echo "  gpu-pose:      ${GPU_POSE}  (M1 COLMAP)"
echo "  gpu-rep:       ${GPU_REP}   (M8 3DGS)"
echo "  iterations:    ${ITERATIONS}"
echo "  skip_pose=${SKIP_POSE}  skip_rep=${SKIP_REP}"

if [ ! -d "${FRAMES_DIR}" ]; then
    echo "[FATAL] frames 디렉토리 없음: ${FRAMES_DIR}"
    echo "        data/README.md §5 layout 규약 참조."
    exit 1
fi
N_FRAMES=$(find "${FRAMES_DIR}" -maxdepth 1 -type f -name '*.png' | wc -l | tr -d ' ')
echo "  n_frames:      ${N_FRAMES}"
if [ "${N_FRAMES}" -eq 0 ]; then
    echo "[FATAL] frames 디렉토리에 PNG 없음."
    exit 1
fi

# ---------------------------------------------------------------
# Stage 1: M1 COLMAP — SfM pose
# ---------------------------------------------------------------
T_POSE_START=$(date +%s)
if [ "${SKIP_POSE}" -eq 0 ]; then
    echo
    echo "----------------------------------------------------------------"
    echo "  Stage 1: M1 COLMAP automatic_reconstructor"
    echo "----------------------------------------------------------------"
    docker run --rm \
        --gpus "\"device=${GPU_POSE}\"" \
        --user "$(id -u):$(id -g)" \
        -v "${DATA_ROOT}:/data" \
        --name "ars-${PIPELINE_ID}-${SITE}-${RUN}-m1" \
        "${M1_IMAGE}" \
        colmap automatic_reconstructor \
            --image_path "/data/sites/${SITE}/runs/${RUN}/frames" \
            --workspace_path "/data/outputs/${PIPELINE_ID}/${SITE}/${RUN}/pose" \
            --camera_model PINHOLE \
            --single_camera 1 \
            --sparse 1 \
            --dense 0 \
            --use_gpu 1 \
            2>&1 | tee "${LOG_DIR}/m1_colmap.log"
else
    echo "[skip] Stage 1 (M1 COLMAP) — --skip-pose"
fi
T_POSE_END=$(date +%s)
T_POSE=$(( T_POSE_END - T_POSE_START ))

# ---------------------------------------------------------------
# Sanity check sparse output
# ---------------------------------------------------------------
SPARSE_DIR="${POSE_DIR}/sparse/0"
if [ ! -f "${SPARSE_DIR}/cameras.bin" ] && [ ! -f "${SPARSE_DIR}/cameras.txt" ]; then
    echo "[FATAL] sparse reconstruction 출력 누락: ${SPARSE_DIR}"
    echo "        COLMAP automatic_reconstructor 실패 가능 (textureless area registration 실패)"
    exit 2
fi

# ---------------------------------------------------------------
# Stage 1.5: COLMAP image_undistorter — OPENCV → PINHOLE
#   3DGS dataset_readers.py 가 OPENCV camera model 거부하므로
#   undistorted images + PINHOLE camera model 로 변환 필수.
#   산출물: pose_undistorted/{images/, sparse/0/}
#   - images/*.png 는 distortion 제거된 새 PNG (frame 수 동일)
#   - sparse/0/ 는 PINHOLE camera model + 동일 pose
#
# IMPORTANT: COLMAP image_undistorter 는 sparse model 을 sparse/ 에
# 직접 출력 (sparse/0/ 아님). 3DGS dataset_readers 는 sparse/0/ 기대
# → post-process mv 로 sparse/*.bin → sparse/0/*.bin 재배치 필수.
#
# Idempotent: pose_undistorted/sparse/0/cameras.{bin,txt} 가 이미 있으면 skip.
# ---------------------------------------------------------------
T_UNDISTORT_START=$(date +%s)
UNDISTORT_DONE=0
if [ -f "${UNDISTORT_DIR}/sparse/0/cameras.bin" ] || [ -f "${UNDISTORT_DIR}/sparse/0/cameras.txt" ]; then
    echo
    echo "[skip] Stage 1.5 (image_undistorter) — undistorted output 이미 존재"
    UNDISTORT_DONE=1
fi
if [ "${SKIP_UNDISTORT}" -eq 0 ] && [ "${UNDISTORT_DONE}" -eq 0 ]; then
    echo
    echo "----------------------------------------------------------------"
    echo "  Stage 1.5: COLMAP image_undistorter (OPENCV → PINHOLE)"
    echo "----------------------------------------------------------------"
    docker run --rm \
        --gpus "\"device=${GPU_POSE}\"" \
        --user "$(id -u):$(id -g)" \
        -v "${DATA_ROOT}:/data" \
        --name "ars-${PIPELINE_ID}-${SITE}-${RUN}-undistort" \
        "${M1_IMAGE}" \
        colmap image_undistorter \
            --image_path  "/data/sites/${SITE}/runs/${RUN}/frames" \
            --input_path  "/data/outputs/${PIPELINE_ID}/${SITE}/${RUN}/pose/sparse/0" \
            --output_path "/data/outputs/${PIPELINE_ID}/${SITE}/${RUN}/pose_undistorted" \
            --output_type COLMAP \
            2>&1 | tee "${LOG_DIR}/m1_undistort.log"

    # Post-process: image_undistorter 의 sparse/ 출력을 sparse/0/ 로 재배치
    # (3DGS dataset_readers.py 의 source_path/sparse/0/ 기대와 매칭)
    if [ -f "${UNDISTORT_DIR}/sparse/cameras.bin" ] && [ ! -f "${UNDISTORT_DIR}/sparse/0/cameras.bin" ]; then
        echo "  [post-undistort] sparse/*.bin → sparse/0/*.bin 재배치"
        mkdir -p "${UNDISTORT_DIR}/sparse/0"
        mv "${UNDISTORT_DIR}/sparse"/*.bin "${UNDISTORT_DIR}/sparse/0/"
    fi
elif [ "${SKIP_UNDISTORT}" -eq 1 ]; then
    echo "[skip] Stage 1.5 (image_undistorter) — --skip-undistort"
fi
T_UNDISTORT_END=$(date +%s)
T_UNDISTORT=$(( T_UNDISTORT_END - T_UNDISTORT_START ))

# Sanity check undistorted output (3DGS 진입 전 필수 검증; sparse/0/ 경로로 검사)
if [ ! -f "${UNDISTORT_DIR}/sparse/0/cameras.bin" ] && [ ! -f "${UNDISTORT_DIR}/sparse/0/cameras.txt" ]; then
    echo "[FATAL] image_undistorter 출력 누락: ${UNDISTORT_DIR}/sparse/0/cameras.{bin,txt}"
    echo "        Stage 1.5 실패 또는 sparse/0/ 재배치 실패 — log 확인: ${LOG_DIR}/m1_undistort.log"
    exit 2
fi

# ---------------------------------------------------------------
# Stage 2: M8 3DGS — volumetric representation (on undistorted PINHOLE)
# ---------------------------------------------------------------
T_REP_START=$(date +%s)
if [ "${SKIP_REP}" -eq 0 ]; then
    echo
    echo "----------------------------------------------------------------"
    echo "  Stage 2: M8 3DGS train (${ITERATIONS} iter)"
    echo "----------------------------------------------------------------"
    docker run --rm \
        --gpus "\"device=${GPU_REP}\"" \
        --user "$(id -u):$(id -g)" \
        -v "${DATA_ROOT}:/data" \
        --name "ars-${PIPELINE_ID}-${SITE}-${RUN}-m8" \
        "${M8_IMAGE}" \
        python /opt/gaussian_splatting/train.py \
            --source_path "/data/outputs/${PIPELINE_ID}/${SITE}/${RUN}/pose_undistorted" \
            --model_path "/data/outputs/${PIPELINE_ID}/${SITE}/${RUN}/recon" \
            --iterations "${ITERATIONS}" \
            --resolution 1 \
            --data_device cpu \
            --eval \
            2>&1 | tee "${LOG_DIR}/m8_3dgs.log"
else
    echo "[skip] Stage 2 (M8 3DGS) — --skip-rep"
fi
T_REP_END=$(date +%s)
T_REP=$(( T_REP_END - T_REP_START ))

# ---------------------------------------------------------------
# Metrics aggregation
# ---------------------------------------------------------------
echo
echo "----------------------------------------------------------------"
echo "  Metrics aggregation"
echo "----------------------------------------------------------------"
# pose time 에 image_undistorter (Stage 1.5) 도 합산 (compute_metrics 의 t-pose 인자 spec)
T_POSE_TOTAL=$(( T_POSE + T_UNDISTORT ))
python3 "$(dirname "${BASH_SOURCE[0]}")/compute_metrics.py" \
    --pipeline "${PIPELINE_ID}" \
    --site "${SITE}" \
    --run "${RUN}" \
    --recon-dir "${RECON_DIR}" \
    --t-pose "${T_POSE_TOTAL}" \
    --t-rep "${T_REP}" \
    --output "${METRICS_FILE}"

# ---------------------------------------------------------------
# Summary
# ---------------------------------------------------------------
echo
echo "================================================================"
echo "  ${PIPELINE_ID} 완료 — site=${SITE} run=${RUN}"
echo "    pose  time (Stage 1):    ${T_POSE}s"
echo "    undistort (Stage 1.5):   ${T_UNDISTORT}s"
echo "    rep   time (Stage 2):    ${T_REP}s"
echo "    output:                  ${OUT_DIR}"
echo "    metrics:                 ${METRICS_FILE}"
echo "================================================================"
