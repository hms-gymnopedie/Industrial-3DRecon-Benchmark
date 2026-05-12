#!/usr/bin/env bash
# =============================================================================
# download_weights.sh — MASt3R-SLAM 의존 weight 다운로드
#
# 다운로드 대상:
#   MASt3R ViT-Large encoder checkpoint (metric depth)
#     Naver Labs Europe CDN
#
# Usage:
#   bash experiments/scripts/download_weights.sh
#   bash experiments/scripts/download_weights.sh --dest /custom/path
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEST_DIR="${REPO_ROOT}/experiments/weights"

while [ $# -gt 0 ]; do
    case "$1" in
        --dest) DEST_DIR="$2"; shift 2 ;;
        -h|--help)
            sed -n '2,12p' "$0"; exit 0 ;;
        *) echo "Unknown argument: $1"; exit 2 ;;
    esac
done

green() { printf "\033[32m%s\033[0m\n" "$*"; }
red()   { printf "\033[31m%s\033[0m\n" "$*"; }
yellow(){ printf "\033[33m%s\033[0m\n" "$*"; }
blue()  { printf "\033[34m%s\033[0m\n" "$*"; }

mkdir -p "${DEST_DIR}"
blue "==============================================================="
blue " MASt3R-SLAM weight download → ${DEST_DIR}"
blue "==============================================================="

# ---------------------------------------------------------------
# Asset registry
#   key: 파일명
#   val: 'URL|expected_sha256(또는 SKIP)'
# ---------------------------------------------------------------
declare -A ASSETS=(
    ["MASt3R_ViTLarge_BaseDecoder_512_catmlpdpt_metric.pth"]="https://download.europe.naverlabs.com/ComputerVision/MASt3R/MASt3R_ViTLarge_BaseDecoder_512_catmlpdpt_metric.pth|SKIP"
)

DL=$(command -v curl >/dev/null 2>&1 && echo curl || echo wget)

fetch() {
    local url="$1" out="$2"
    if [ "${DL}" = "curl" ]; then
        curl -L --fail --retry 3 --connect-timeout 30 -o "${out}.part" "${url}"
    else
        wget -O "${out}.part" --tries=3 --timeout=30 "${url}"
    fi
    mv "${out}.part" "${out}"
}

verify_sha256() {
    local file="$1" expected="$2"
    if [ "${expected}" = "SKIP" ]; then
        yellow "  [SKIP] sha256 검증 생략 (upstream에서 공식 hash 미공개)"
        return 0
    fi
    local actual
    if command -v sha256sum >/dev/null 2>&1; then
        actual=$(sha256sum "${file}" | awk '{print $1}')
    elif command -v shasum >/dev/null 2>&1; then
        actual=$(shasum -a 256 "${file}" | awk '{print $1}')
    else
        yellow "  [SKIP] sha256 검증 도구 없음"
        return 0
    fi
    if [ "${actual}" = "${expected}" ]; then
        green "  [OK] sha256 일치"
    else
        red "  [FAIL] sha256 불일치"
        red "    expected: ${expected}"
        red "    actual:   ${actual}"
        return 1
    fi
}

# ---------------------------------------------------------------
# Download loop
# ---------------------------------------------------------------
FAIL=0
for fname in "${!ASSETS[@]}"; do
    spec="${ASSETS[$fname]}"
    url="${spec%%|*}"
    sha="${spec##*|}"
    out="${DEST_DIR}/${fname}"

    echo
    blue "[asset] ${fname}"
    if [ -f "${out}" ]; then
        size=$(stat -f%z "${out}" 2>/dev/null || stat -c%s "${out}" 2>/dev/null || echo "?")
        yellow "  이미 존재 (${size} bytes) — skip 다운로드, sha 검증만 수행"
    else
        echo "  URL: ${url}"
        if ! fetch "${url}" "${out}"; then
            red "  [FAIL] 다운로드 실패"
            FAIL=$((FAIL+1))
            continue
        fi
    fi
    if ! verify_sha256 "${out}" "${sha}"; then
        FAIL=$((FAIL+1))
    fi
done

echo
blue "==============================================================="
if [ "${FAIL}" -eq 0 ]; then
    green " 모든 weight 준비 완료."
    green " M7 docker run 시: -v ${DEST_DIR}:/weights"
    echo
    echo "다음 단계: bash experiments/scripts/verify_dockers.sh"
else
    red " ${FAIL}개 자산 처리 실패. URL 갱신 또는 네트워크 점검."
    exit 1
fi
blue "==============================================================="
