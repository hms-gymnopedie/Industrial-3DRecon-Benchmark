#!/usr/bin/env bash
# =============================================================================
# reorganize_frames.sh
#   사용자 raw PNG layout → ARS 표준 layout 변환 (symlink 기반 default).
#
# 사용자 원본 (가정 — 이미 site/run nested):
#   {SRC_ROOT}/{site}/{run}/*.png
#   예: /data/minsuh/raw_frames/I-1/run-01/0001.png
#
# ARS 표준 출력 (data/README.md §1):
#   {DEST_ROOT}/sites/{site}/runs/{run}/frames/*.png
#   예: /data/minsuh/experiment/data/sites/I-1/runs/run-01/frames/0001.png
#
# Default mode: symlink (디스크 중복 없음). rsync / mv 도 선택 가능.
#
# Usage:
#   bash reorganize_frames.sh \
#        --src  /data/minsuh/raw_frames \
#        --dest /data/minsuh/experiment/data \
#        --sites "I-1 I-2 I-3 L-1 L-2 L-3" \
#        --runs  "run-01" \
#        --mode  symlink
#
# 옵션:
#   --src       원본 PNG root (필수)
#   --dest      ARS data root (예: /data/minsuh/experiment/data)
#   --sites     공백 구분 site ID 목록 (default: "I-1 I-2 I-3 L-1 L-2 L-3")
#   --runs      공백 구분 run ID 목록 (default: "run-01")
#   --mode      symlink (default) | rsync | mv
#   --dry-run   변환 plan 출력만, 실제 작업 미수행
# =============================================================================
set -euo pipefail

SRC_ROOT=""
DEST_ROOT=""
SITES="I-1 I-2 I-3 L-1 L-2 L-3"
RUNS="run-01"
MODE="symlink"
DRY_RUN=0

while [ $# -gt 0 ]; do
    case "$1" in
        --src)      SRC_ROOT="$2"; shift 2 ;;
        --dest)     DEST_ROOT="$2"; shift 2 ;;
        --sites)    SITES="$2"; shift 2 ;;
        --runs)     RUNS="$2"; shift 2 ;;
        --mode)     MODE="$2"; shift 2 ;;
        --dry-run)  DRY_RUN=1; shift ;;
        -h|--help)  sed -n '2,30p' "$0"; exit 0 ;;
        *)          echo "Unknown arg: $1"; exit 2 ;;
    esac
done

[ -z "${SRC_ROOT}" ]  && { echo "[FATAL] --src 필수"; exit 2; }
[ -z "${DEST_ROOT}" ] && { echo "[FATAL] --dest 필수"; exit 2; }
[ -d "${SRC_ROOT}" ]  || { echo "[FATAL] src 디렉토리 없음: ${SRC_ROOT}"; exit 2; }

case "${MODE}" in
    symlink|rsync|mv) ;;
    *) echo "[FATAL] --mode 는 symlink|rsync|mv 중 하나"; exit 2 ;;
esac

blue()  { printf "\033[34m%s\033[0m\n" "$*"; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }
yellow(){ printf "\033[33m%s\033[0m\n" "$*"; }
red()   { printf "\033[31m%s\033[0m\n" "$*"; }

blue "============================================================"
blue "  reorganize_frames.sh"
blue "  src       : ${SRC_ROOT}"
blue "  dest      : ${DEST_ROOT}"
blue "  sites     : ${SITES}"
blue "  runs      : ${RUNS}"
blue "  mode      : ${MODE}"
blue "  dry-run   : ${DRY_RUN}"
blue "============================================================"

TOTAL_FRAMES=0
TOTAL_PAIRS=0
SKIPPED=0

for SITE in ${SITES}; do
    for RUN in ${RUNS}; do
        SRC_DIR="${SRC_ROOT}/${SITE}/${RUN}"
        DEST_DIR="${DEST_ROOT}/sites/${SITE}/runs/${RUN}/frames"

        TOTAL_PAIRS=$((TOTAL_PAIRS + 1))

        if [ ! -d "${SRC_DIR}" ]; then
            yellow "[skip] ${SITE}/${RUN}: src 없음 — ${SRC_DIR}"
            SKIPPED=$((SKIPPED + 1))
            continue
        fi

        # PNG 카운트 (실제 작업 전 plan 검증)
        N_PNG=$(find "${SRC_DIR}" -maxdepth 1 -name "*.png" -type f | wc -l | tr -d ' ')
        if [ "${N_PNG}" -eq 0 ]; then
            yellow "[skip] ${SITE}/${RUN}: PNG 0개 — ${SRC_DIR}"
            SKIPPED=$((SKIPPED + 1))
            continue
        fi

        echo "[${SITE}/${RUN}] N=${N_PNG} PNG  ${SRC_DIR} → ${DEST_DIR}"

        if [ "${DRY_RUN}" -eq 1 ]; then
            TOTAL_FRAMES=$((TOTAL_FRAMES + N_PNG))
            continue
        fi

        mkdir -p "${DEST_DIR}"

        case "${MODE}" in
            symlink)
                # 절대경로 symlink 로 src → dest 매핑.
                # PNG 만 (선별), hidden file 제외.
                for f in "${SRC_DIR}"/*.png; do
                    [ -f "$f" ] || continue
                    fname=$(basename "$f")
                    ln -sfn "$f" "${DEST_DIR}/${fname}"
                done
                ;;
            rsync)
                rsync -a --include="*.png" --exclude="*" "${SRC_DIR}/" "${DEST_DIR}/"
                ;;
            mv)
                # 비파괴 검증 — dest 가 비어 있을 때만 mv
                if [ -n "$(ls -A "${DEST_DIR}" 2>/dev/null || true)" ]; then
                    red "[FATAL] mv 모드: dest 비어 있지 않음 — ${DEST_DIR}"
                    exit 1
                fi
                mv "${SRC_DIR}"/*.png "${DEST_DIR}/"
                ;;
        esac

        TOTAL_FRAMES=$((TOTAL_FRAMES + N_PNG))
    done
done

echo
blue "============================================================"
green "  변환 완료"
echo "  처리 pair : $((TOTAL_PAIRS - SKIPPED)) / ${TOTAL_PAIRS}"
echo "  skipped   : ${SKIPPED}"
echo "  총 frame  : ${TOTAL_FRAMES}"
blue "============================================================"

# 후속 안내
cat <<EOF

[다음 단계]
1) calib 디렉토리는 P1 COLMAP self-calibration 후 자동 생성:
     bash experiments/scripts/run_pipeline_p1.sh \\
          --site I-1 --run ${RUN} \\
          --data-root ${DEST_ROOT}

2) P1 종료 후 intrinsics 추출 → P9 재사용:
     python experiments/adapters/colmap_to_intrinsics.py \\
          --cameras ${DEST_ROOT}/outputs/P1/{site}/{run}/pose/sparse/0/cameras.bin \\
          --output  ${DEST_ROOT}/sites/{site}/calib/intrinsics.json

3) Pilot driver 실행:
     bash experiments/scripts/run_pilot_i1.sh \\
          --single-host \\
          --data-root ${DEST_ROOT}
EOF
