#!/usr/bin/env bash
# =============================================================================
# run_pipeline_p1.sh — P1 (H-Worst) end-to-end pipeline
#   Stage 1: M1 COLMAP (SfM pose)
#   Stage 2: M8 3DGS (volumetric representation)
#
# Pre-registered hypothesis: H-Worst — hand-crafted SfM + volumetric primitives
# 산업현장 textureless / reflective / dynamic 도메인에서 최하위 성능 예상.
#
# Usage:
#   run_pipeline_p1.sh [--site I-1] [--run run-01] [--gpu-pose 0] [--gpu-rep 1] \
#                     [--data-root ./data] [--iterations 30000] [--skip-pose|--skip-rep]
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
        --skip-pose)   SKIP_POSE=1; shift ;;
        --skip-rep)    SKIP_REP=1; shift ;;
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
RECON_DIR="${OUT_DIR}/recon"
LOG_DIR="${OUT_DIR}/logs"
METRICS_FILE="${OUT_DIR}/metrics.json"

mkdir -p "${POSE_DIR}" "${RECON_DIR}" "${LOG_DIR}"

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
        -v "${DATA_ROOT}:/data" \
        --name "ars-${PIPELINE_ID}-${SITE}-${RUN}-m1" \
        "${M1_IMAGE}" \
        colmap automatic_reconstructor \
            --image_path "/data/sites/${SITE}/runs/${RUN}/frames" \
            --workspace_path "/data/outputs/${PIPELINE_ID}/${SITE}/${RUN}/pose" \
            --camera_model OPENCV \
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
# Stage 2: M8 3DGS — volumetric representation
# ---------------------------------------------------------------
T_REP_START=$(date +%s)
if [ "${SKIP_REP}" -eq 0 ]; then
    echo
    echo "----------------------------------------------------------------"
    echo "  Stage 2: M8 3DGS train (${ITERATIONS} iter)"
    echo "----------------------------------------------------------------"
    docker run --rm \
        --gpus "\"device=${GPU_REP}\"" \
        -v "${DATA_ROOT}:/data" \
        --name "ars-${PIPELINE_ID}-${SITE}-${RUN}-m8" \
        "${M8_IMAGE}" \
        python /opt/gaussian_splatting/train.py \
            --source_path "/data/outputs/${PIPELINE_ID}/${SITE}/${RUN}/pose" \
            --images "/data/sites/${SITE}/runs/${RUN}/frames" \
            --model_path "/data/outputs/${PIPELINE_ID}/${SITE}/${RUN}/recon" \
            --iterations "${ITERATIONS}" \
            --resolution 1 \
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
python3 "$(dirname "${BASH_SOURCE[0]}")/compute_metrics.py" \
    --pipeline "${PIPELINE_ID}" \
    --site "${SITE}" \
    --run "${RUN}" \
    --recon-dir "${RECON_DIR}" \
    --t-pose "${T_POSE}" \
    --t-rep "${T_REP}" \
    --output "${METRICS_FILE}"

# ---------------------------------------------------------------
# Summary
# ---------------------------------------------------------------
echo
echo "================================================================"
echo "  ${PIPELINE_ID} 완료 — site=${SITE} run=${RUN}"
echo "    pose time:  ${T_POSE}s"
echo "    rep  time:  ${T_REP}s"
echo "    output:     ${OUT_DIR}"
echo "    metrics:    ${METRICS_FILE}"
echo "================================================================"
