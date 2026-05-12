#!/usr/bin/env bash
# =============================================================================
# verify_gpu.sh — host driver / CUDA / docker GPU runtime 검증
# Usage: bash experiments/scripts/verify_gpu.sh
# =============================================================================
set -euo pipefail

PASS=0
FAIL=0

green() { printf "\033[32m%s\033[0m\n" "$*"; }
red()   { printf "\033[31m%s\033[0m\n" "$*"; }
yellow(){ printf "\033[33m%s\033[0m\n" "$*"; }

check() {
    local label="$1"; shift
    if "$@" >/dev/null 2>&1; then
        green  "  [PASS] $label"
        PASS=$((PASS+1))
    else
        red    "  [FAIL] $label"
        FAIL=$((FAIL+1))
    fi
}

echo "==============================================================="
echo " ARS Experiment Setup — Host GPU verification"
echo "==============================================================="

# ---------------------------------------------------------------
# 1. NVIDIA driver
# ---------------------------------------------------------------
echo
echo "[1/5] NVIDIA driver"
if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
    check "nvidia-smi 실행 가능" nvidia-smi
else
    red "  [FAIL] nvidia-smi 명령 없음 — NVIDIA driver 설치 필요"
    FAIL=$((FAIL+1))
fi

# ---------------------------------------------------------------
# 2. GPU 개수 & 모델 확인 (RTX 4090 기대)
# ---------------------------------------------------------------
echo
echo "[2/5] GPU 개수 / 모델"
if command -v nvidia-smi >/dev/null 2>&1; then
    GPU_COUNT=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l | tr -d ' ')
    echo "  탐지된 GPU: ${GPU_COUNT}개"
    GPU_4090=$(nvidia-smi --query-gpu=name --format=csv,noheader | grep -c "4090" || true)
    if [ "${GPU_4090}" -gt 0 ]; then
        green "  [PASS] RTX 4090 ${GPU_4090}개 인식"
        PASS=$((PASS+1))
    else
        yellow "  [WARN] RTX 4090 미탐지 — 다른 GPU 사용 시 Dockerfile의 TORCH_CUDA_ARCH_LIST 재설정 필요"
    fi
fi

# ---------------------------------------------------------------
# 3. CUDA toolkit (호스트, 선택)
# ---------------------------------------------------------------
echo
echo "[3/5] CUDA driver API version (nvidia-smi에서 보고)"
if command -v nvidia-smi >/dev/null 2>&1; then
    CUDA_VER=$(nvidia-smi | grep -oP 'CUDA Version: \K[0-9.]+' | head -1 || echo "unknown")
    echo "  CUDA driver API: ${CUDA_VER}"
    # 컨테이너 CUDA 11.8 호환 driver = ≥ 520.61.05 (Linux)
    if [ "${CUDA_VER}" != "unknown" ]; then
        green "  [PASS] CUDA driver API 응답 (컨테이너 CUDA 11.8 base는 driver ≥520.x 필요)"
        PASS=$((PASS+1))
    else
        yellow "  [WARN] CUDA version 파싱 실패"
    fi
fi

# ---------------------------------------------------------------
# 4. Docker + NVIDIA Container Toolkit
# ---------------------------------------------------------------
echo
echo "[4/5] Docker + NVIDIA Container Toolkit"
check "docker 명령 사용 가능" command -v docker
check "docker daemon 응답"   docker info

# nvidia-container-runtime / nvidia-ctk 검증
if docker info 2>/dev/null | grep -qi "nvidia"; then
    green "  [PASS] docker info에 nvidia runtime 등록 확인"
    PASS=$((PASS+1))
else
    yellow "  [WARN] docker info에서 nvidia runtime 미확인 — nvidia-container-toolkit 설치 점검"
fi

# ---------------------------------------------------------------
# 5. GPU container smoke test
# ---------------------------------------------------------------
echo
echo "[5/5] GPU container smoke test (nvidia/cuda:11.8.0-base)"
if docker pull --quiet nvidia/cuda:11.8.0-base-ubuntu22.04 >/dev/null 2>&1; then
    if docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 \
            nvidia-smi --query-gpu=name --format=csv,noheader >/dev/null 2>&1; then
        green "  [PASS] docker --gpus all 정상 동작"
        PASS=$((PASS+1))
    else
        red "  [FAIL] 'docker run --gpus all'에서 GPU 인식 실패"
        FAIL=$((FAIL+1))
    fi
else
    yellow "  [SKIP] nvidia/cuda:11.8.0-base image pull 실패 (네트워크 점검)"
fi

# ---------------------------------------------------------------
# Summary
# ---------------------------------------------------------------
echo
echo "==============================================================="
printf " 결과: \033[32mPASS %d\033[0m / \033[31mFAIL %d\033[0m\n" "${PASS}" "${FAIL}"
echo "==============================================================="

if [ "${FAIL}" -gt 0 ]; then
    echo
    yellow "FAIL이 있으면 다음 단계 (verify_dockers.sh) 진입 전에 해결 필요."
    yellow " - driver 미설치: https://www.nvidia.com/Download/index.aspx"
    yellow " - NVIDIA Container Toolkit:"
    yellow "     https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html"
    exit 1
fi

green "모든 검증 통과. 다음: bash experiments/scripts/download_weights.sh"
