#!/usr/bin/env bash
# =============================================================================
# verify_dockers.sh — Tier 1 4개 docker image build + smoke test
#  - M1 COLMAP  (ars/m1_colmap:3.9.1)
#  - M7 MASt3R-SLAM (ars/m7_mast3r_slam:latest)
#  - M8 3DGS    (ars/m8_3dgs:latest)
#  - M9 2DGS    (ars/m9_2dgs:latest)
#
# Usage:
#   bash experiments/scripts/verify_dockers.sh            # build all + smoke
#   bash experiments/scripts/verify_dockers.sh --skip-build # smoke only
#   bash experiments/scripts/verify_dockers.sh m7 m9      # subset (m1|m7|m8|m9)
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXP_ROOT="${REPO_ROOT}/experiments"

green() { printf "\033[32m%s\033[0m\n" "$*"; }
red()   { printf "\033[31m%s\033[0m\n" "$*"; }
yellow(){ printf "\033[33m%s\033[0m\n" "$*"; }
blue()  { printf "\033[34m%s\033[0m\n" "$*"; }

# ---------------------------------------------------------------
# Image registry (id → tag, build context, smoke command)
# ---------------------------------------------------------------
declare -A TAG=(
    [m1]="ars/m1_colmap:3.9.1"
    [m7]="ars/m7_mast3r_slam:latest"
    [m8]="ars/m8_3dgs:latest"
    [m9]="ars/m9_2dgs:latest"
)
declare -A CTX=(
    [m1]="${EXP_ROOT}/docker/m1_colmap"
    [m7]="${EXP_ROOT}/docker/m7_mast3r_slam"
    [m8]="${EXP_ROOT}/docker/m8_3dgs"
    [m9]="${EXP_ROOT}/docker/m9_2dgs"
)
declare -A SMOKE=(
    [m1]="colmap --help"
    [m7]="python -c 'import torch; print(\"torch\", torch.__version__, \"cuda\", torch.cuda.is_available())'"
    [m8]="python -c 'import torch, diff_gaussian_rasterization, simple_knn; print(\"3DGS OK\")'"
    [m9]="python -c 'import torch, diff_surfel_rasterization, simple_knn; print(\"2DGS OK\")'"
)

# ---------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------
SKIP_BUILD=0
TARGETS=()
while [ $# -gt 0 ]; do
    case "$1" in
        --skip-build) SKIP_BUILD=1; shift ;;
        m1|m7|m8|m9)  TARGETS+=("$1"); shift ;;
        -h|--help)
            sed -n '2,15p' "$0"; exit 0 ;;
        *) red "Unknown argument: $1"; exit 2 ;;
    esac
done
if [ ${#TARGETS[@]} -eq 0 ]; then
    TARGETS=(m1 m7 m8 m9)
fi

# ---------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------
if ! command -v docker >/dev/null 2>&1; then
    red "docker 명령 없음. verify_gpu.sh 먼저 실행."
    exit 1
fi

# ---------------------------------------------------------------
# Build phase
# ---------------------------------------------------------------
BUILD_FAIL=0
if [ "${SKIP_BUILD}" -eq 0 ]; then
    blue "==============================================================="
    blue " Build phase — targets: ${TARGETS[*]}"
    blue "==============================================================="
    for id in "${TARGETS[@]}"; do
        echo
        blue "[build] ${id} → ${TAG[$id]}"
        if docker build -t "${TAG[$id]}" "${CTX[$id]}"; then
            green "  [OK] ${TAG[$id]} build 성공"
        else
            red   "  [FAIL] ${TAG[$id]} build 실패"
            BUILD_FAIL=$((BUILD_FAIL+1))
        fi
    done
else
    yellow "Build phase skipped (--skip-build)"
fi

if [ "${BUILD_FAIL}" -gt 0 ]; then
    red "Build 단계에서 ${BUILD_FAIL}개 실패. Smoke phase 진입 안 함."
    exit 1
fi

# ---------------------------------------------------------------
# Smoke phase
# ---------------------------------------------------------------
echo
blue "==============================================================="
blue " Smoke test phase — GPU 인식 + 핵심 모듈 import 확인"
blue "==============================================================="
SMOKE_FAIL=0
for id in "${TARGETS[@]}"; do
    echo
    blue "[smoke] ${id} (${TAG[$id]})"
    if docker run --rm --gpus all "${TAG[$id]}" bash -lc "${SMOKE[$id]}"; then
        green "  [OK] ${id} smoke pass"
    else
        red   "  [FAIL] ${id} smoke fail"
        SMOKE_FAIL=$((SMOKE_FAIL+1))
    fi
done

echo
blue "==============================================================="
if [ "${SMOKE_FAIL}" -eq 0 ]; then
    green " 전체 ${#TARGETS[@]}개 image 검증 통과."
    green " 다음 단계: P1 / P9 end-to-end orchestration (Tier 2)"
else
    red " ${SMOKE_FAIL}개 smoke test 실패. Dockerfile / driver / CUDA arch 점검."
fi
blue "==============================================================="

exit "${SMOKE_FAIL}"
