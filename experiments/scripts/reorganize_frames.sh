#!/usr/bin/env bash
# =============================================================================
# reorganize_frames.sh
#   사용자 raw PNG layout → ARS 표준 layout 변환 (symlink 기반 default).
#
# 사용자 원본 — video-to-image 모듈이 site/run 아래 sharp/mask 두 sub-folder
# 분리 출력 (sharp = RGB frame, mask = SAM2/YOLO 계 dynamic instance mask):
#   {SRC_ROOT}/{site}/{run}/sharp/*.png       ← 학습 입력 frame
#   {SRC_ROOT}/{site}/{run}/mask/*.png        ← frames 와 1:1 매칭되는 mask
#   예:
#     /data/minsuh/raw_frames/I-1/run-01/sharp/0001.png
#     /data/minsuh/raw_frames/I-1/run-01/mask/0001.png
#
# ARS 표준 출력 (data/README.md §2):
#   {DEST_ROOT}/sites/{site}/runs/{run}/frames/*.png   ← sharp 와 mapping
#   {DEST_ROOT}/sites/{site}/runs/{run}/masks/*.png    ← mask 와 mapping
#
# Default mode: symlink (디스크 중복 없음). rsync / mv 도 선택 가능.
# Mask 폴더는 사용자 측에 없을 수 있음 — 없으면 자동 skip.
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
#   --src         원본 root (필수, {site}/{run}/{sharp,mask}/ 구조 가정)
#   --dest        ARS data root (예: /data/minsuh/experiment/data)
#   --sites       공백 구분 site ID 목록 (default: "I-1 I-2 I-3 L-1 L-2 L-3")
#   --runs        공백 구분 run ID 목록 (default: "run-01")
#   --mode        symlink (default) | rsync | mv
#   --sharp-dir   sharp sub-folder 이름 변경 (default: "sharp")
#   --mask-dir    mask sub-folder 이름 변경 (default: "mask")
#   --skip-mask   mask 폴더 자체를 무시 (sharp 만 처리)
#   --dry-run     변환 plan 출력만, 실제 작업 미수행
# =============================================================================
set -euo pipefail

SRC_ROOT=""
DEST_ROOT=""
SITES="I-1 I-2 I-3 L-1 L-2 L-3"
RUNS="run-01"
MODE="symlink"
SHARP_SUB="sharp"
MASK_SUB="mask"
SKIP_MASK=0
DRY_RUN=0

while [ $# -gt 0 ]; do
    case "$1" in
        --src)         SRC_ROOT="$2"; shift 2 ;;
        --dest)        DEST_ROOT="$2"; shift 2 ;;
        --sites)       SITES="$2"; shift 2 ;;
        --runs)        RUNS="$2"; shift 2 ;;
        --mode)        MODE="$2"; shift 2 ;;
        --sharp-dir)   SHARP_SUB="$2"; shift 2 ;;
        --mask-dir)    MASK_SUB="$2"; shift 2 ;;
        --skip-mask)   SKIP_MASK=1; shift ;;
        --dry-run)     DRY_RUN=1; shift ;;
        -h|--help)     sed -n '2,40p' "$0"; exit 0 ;;
        *)             echo "Unknown arg: $1"; exit 2 ;;
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
blue "  src         : ${SRC_ROOT}"
blue "  dest        : ${DEST_ROOT}"
blue "  sites       : ${SITES}"
blue "  runs        : ${RUNS}"
blue "  mode        : ${MODE}"
blue "  sharp/mask  : ${SHARP_SUB}/${MASK_SUB}  (skip-mask=${SKIP_MASK})"
blue "  dry-run     : ${DRY_RUN}"
blue "============================================================"

# ---------------------------------------------------------------
# 한 sub-folder (sharp 또는 mask) 처리 함수
#   $1 = SRC_SUB_DIR (절대 경로)
#   $2 = DEST_SUB_DIR (절대 경로)
#   $3 = label ("sharp" / "mask") for 로그
# 반환 (전역): _N_PROCESSED — symlink 된 PNG 수
# ---------------------------------------------------------------
_N_PROCESSED=0
process_sub_folder() {
    local src_dir="$1"
    local dest_dir="$2"
    local label="$3"

    _N_PROCESSED=0

    if [ ! -d "${src_dir}" ]; then
        return 0
    fi

    local n_png
    n_png=$(find "${src_dir}" -maxdepth 1 -name "*.png" -type f | wc -l | tr -d ' ')
    if [ "${n_png}" -eq 0 ]; then
        return 0
    fi

    echo "  [${label}] N=${n_png}  ${src_dir} → ${dest_dir}"

    if [ "${DRY_RUN}" -eq 1 ]; then
        _N_PROCESSED="${n_png}"
        return 0
    fi

    mkdir -p "${dest_dir}"

    case "${MODE}" in
        symlink)
            local f fname
            for f in "${src_dir}"/*.png; do
                [ -f "$f" ] || continue
                fname=$(basename "$f")
                ln -sfn "$f" "${dest_dir}/${fname}"
            done
            ;;
        rsync)
            rsync -a --include="*.png" --exclude="*" "${src_dir}/" "${dest_dir}/"
            ;;
        mv)
            if [ -n "$(ls -A "${dest_dir}" 2>/dev/null || true)" ]; then
                red "[FATAL] mv 모드: dest 비어 있지 않음 — ${dest_dir}"
                exit 1
            fi
            mv "${src_dir}"/*.png "${dest_dir}/"
            ;;
    esac

    _N_PROCESSED="${n_png}"
}

# ---------------------------------------------------------------
# 메인 loop
# ---------------------------------------------------------------
TOTAL_SHARP=0
TOTAL_MASK=0
TOTAL_PAIRS=0
PROCESSED_PAIRS=0
SKIPPED_PAIRS=0

for SITE in ${SITES}; do
    for RUN in ${RUNS}; do
        TOTAL_PAIRS=$((TOTAL_PAIRS + 1))

        SRC_BASE="${SRC_ROOT}/${SITE}/${RUN}"

        if [ ! -d "${SRC_BASE}" ]; then
            yellow "[skip] ${SITE}/${RUN}: src 없음 — ${SRC_BASE}"
            SKIPPED_PAIRS=$((SKIPPED_PAIRS + 1))
            continue
        fi

        echo "[${SITE}/${RUN}]"

        # sharp 처리 (frames/)
        process_sub_folder \
            "${SRC_BASE}/${SHARP_SUB}" \
            "${DEST_ROOT}/sites/${SITE}/runs/${RUN}/frames" \
            "sharp"
        n_sharp="${_N_PROCESSED}"

        # mask 처리 (masks/)
        n_mask=0
        if [ "${SKIP_MASK}" -eq 0 ]; then
            process_sub_folder \
                "${SRC_BASE}/${MASK_SUB}" \
                "${DEST_ROOT}/sites/${SITE}/runs/${RUN}/masks" \
                "mask"
            n_mask="${_N_PROCESSED}"
        fi

        if [ "${n_sharp}" -eq 0 ] && [ "${n_mask}" -eq 0 ]; then
            yellow "  [skip] sharp / mask 모두 비어 있음 — ${SRC_BASE}"
            SKIPPED_PAIRS=$((SKIPPED_PAIRS + 1))
            continue
        fi

        # 1:1 매칭 sanity check (둘 다 있을 때만)
        if [ "${n_sharp}" -gt 0 ] && [ "${n_mask}" -gt 0 ] && [ "${n_sharp}" -ne "${n_mask}" ]; then
            yellow "  [warn] sharp(${n_sharp}) ≠ mask(${n_mask}) — 파일명 1:1 매칭 검증 필요"
        fi

        TOTAL_SHARP=$((TOTAL_SHARP + n_sharp))
        TOTAL_MASK=$((TOTAL_MASK + n_mask))
        PROCESSED_PAIRS=$((PROCESSED_PAIRS + 1))
    done
done

echo
blue "============================================================"
green "  변환 완료"
echo "  처리 pair : ${PROCESSED_PAIRS} / ${TOTAL_PAIRS}"
echo "  skipped   : ${SKIPPED_PAIRS}"
echo "  총 sharp  : ${TOTAL_SHARP}"
echo "  총 mask   : ${TOTAL_MASK}"
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

[Mask 사용 안내]
- masks/ 폴더는 §4.5e cluster B.1 ablation (mask on/off) 의 입력으로 사용.
- P1 / P9 의 primary 학습 입력은 frames/ 만 사용; masks/ 는 ablation stage 에서만 활성화.
EOF
