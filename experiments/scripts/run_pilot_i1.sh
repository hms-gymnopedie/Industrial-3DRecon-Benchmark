#!/usr/bin/env bash
# =============================================================================
# run_pilot_i1.sh — I-1 site pilot driver (P1 H-Worst vs P9 H-Best 비교)
#
# 본 스크립트는 사전등록된 핵심 가설 검증을 위한 minimal pilot 실행 드라이버.
# 4 GPU (2 host × 2 GPU) 환경에서 P1과 P9를 병렬 실행.
#
# Topology (default — single host 4 GPU 또는 2 host × 2 GPU 모두 적용):
#   P1 stage 1 (M1 COLMAP)       → GPU 0
#   P1 stage 2 (M8 3DGS)         → GPU 1
#   P9 stage 1 (M7 MASt3R-SLAM)  → GPU 2 (host B: device=0)
#   P9 stage 3 (M9 2DGS)         → GPU 3 (host B: device=1)
#
# Single-host 가정 (4 GPU 한 호스트):
#   bash run_pilot_i1.sh --single-host
#
# Two-host 가정 (이 스크립트는 host A에서 P1, host B에서 P9를 따로 실행):
#   # host A
#   bash run_pilot_i1.sh --only p1 --gpu-pose 0 --gpu-rep 1
#   # host B
#   bash run_pilot_i1.sh --only p9 --gpu-pose 0 --gpu-rep 1
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SITE="I-1"
RUN="run-01"
ITERATIONS=30000
DATA_ROOT=""
WEIGHTS_DIR=""
ONLY=""
SINGLE_HOST=0

# Single-host (4 GPU) default mapping
P1_GPU_POSE=0
P1_GPU_REP=1
P9_GPU_POSE=2
P9_GPU_REP=3

while [ $# -gt 0 ]; do
    case "$1" in
        --site)         SITE="$2"; shift 2 ;;
        --run)          RUN="$2"; shift 2 ;;
        --iterations)   ITERATIONS="$2"; shift 2 ;;
        --data-root)    DATA_ROOT="$2"; shift 2 ;;
        --weights)      WEIGHTS_DIR="$2"; shift 2 ;;
        --only)         ONLY="$2"; shift 2 ;;            # p1 | p9
        --single-host)  SINGLE_HOST=1; shift ;;
        --gpu-pose)     P1_GPU_POSE="$2"; P9_GPU_POSE="$2"; shift 2 ;;
        --gpu-rep)      P1_GPU_REP="$2";  P9_GPU_REP="$2";  shift 2 ;;
        -h|--help)      sed -n '2,25p' "$0"; exit 0 ;;
        *) echo "Unknown arg: $1"; exit 2 ;;
    esac
done

# When --only is set, fall back to host-local GPU 0/1 (two-host topology)
if [ -n "${ONLY}" ] && [ "${SINGLE_HOST}" -eq 0 ]; then
    P1_GPU_POSE=${P1_GPU_POSE:-0}; P1_GPU_REP=${P1_GPU_REP:-1}
    P9_GPU_POSE=${P9_GPU_POSE:-0}; P9_GPU_REP=${P9_GPU_REP:-1}
fi

DATA_ARG=""
[ -n "${DATA_ROOT}" ]    && DATA_ARG="--data-root ${DATA_ROOT}"
WEIGHTS_ARG=""
[ -n "${WEIGHTS_DIR}" ]  && WEIGHTS_ARG="--weights ${WEIGHTS_DIR}"

green() { printf "\033[32m%s\033[0m\n" "$*"; }
red()   { printf "\033[31m%s\033[0m\n" "$*"; }
blue()  { printf "\033[34m%s\033[0m\n" "$*"; }

# ---------------------------------------------------------------
# Job spec
# ---------------------------------------------------------------
P1_CMD=(bash "${SCRIPT_DIR}/run_pipeline_p1.sh"
        --site "${SITE}" --run "${RUN}" --iterations "${ITERATIONS}"
        --gpu-pose "${P1_GPU_POSE}" --gpu-rep "${P1_GPU_REP}"
        ${DATA_ARG})

P9_CMD=(bash "${SCRIPT_DIR}/run_pipeline_p9.sh"
        --site "${SITE}" --run "${RUN}" --iterations "${ITERATIONS}"
        --gpu-pose "${P9_GPU_POSE}" --gpu-rep "${P9_GPU_REP}"
        ${DATA_ARG} ${WEIGHTS_ARG})

blue "============================================================"
blue "  ARS Pilot Driver — site=${SITE} run=${RUN}"
blue "  iterations=${ITERATIONS}"
blue "  P1 GPU: pose=${P1_GPU_POSE} rep=${P1_GPU_REP}"
blue "  P9 GPU: pose=${P9_GPU_POSE} rep=${P9_GPU_REP}"
blue "  mode:   only='${ONLY:-both}' single_host=${SINGLE_HOST}"
blue "============================================================"

# ---------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------
case "${ONLY}" in
    p1)
        echo "[only=p1] Running P1 only"
        "${P1_CMD[@]}"
        ;;
    p9)
        echo "[only=p9] Running P9 only"
        "${P9_CMD[@]}"
        ;;
    "")
        if [ "${SINGLE_HOST}" -eq 1 ]; then
            echo "[mode=single-host] P1 + P9 동시 병렬 실행"
            "${P1_CMD[@]}" > >(sed 's/^/[P1] /') 2>&1 &
            PID_P1=$!
            "${P9_CMD[@]}" > >(sed 's/^/[P9] /') 2>&1 &
            PID_P9=$!
            FAIL=0
            wait "${PID_P1}" || { red "P1 실패 (PID ${PID_P1})"; FAIL=$((FAIL+1)); }
            wait "${PID_P9}" || { red "P9 실패 (PID ${PID_P9})"; FAIL=$((FAIL+1)); }
            if [ "${FAIL}" -gt 0 ]; then
                red "Pilot 실패: ${FAIL} pipeline error"
                exit 1
            fi
        else
            echo "[mode=two-host] 본 호스트에서 P1 sequentially → P9"
            "${P1_CMD[@]}"
            "${P9_CMD[@]}"
        fi
        ;;
    *)
        red "Unknown --only value: ${ONLY} (use p1|p9)"
        exit 2
        ;;
esac

# ---------------------------------------------------------------
# Compare summary
# ---------------------------------------------------------------
echo
blue "============================================================"
blue "  Pilot Compare Summary"
blue "============================================================"
M1_JSON="${DATA_ROOT:-data}/outputs/P1/${SITE}/${RUN}/metrics.json"
M9_JSON="${DATA_ROOT:-data}/outputs/P9/${SITE}/${RUN}/metrics.json"

python3 - "${M1_JSON}" "${M9_JSON}" <<'PY' || true
import json, os, sys
p1_path, p9_path = sys.argv[1], sys.argv[2]
def load(p):
    if not os.path.exists(p): return None
    with open(p) as f: return json.load(f)
p1, p9 = load(p1_path), load(p9_path)
if not p1 and not p9:
    print("(metrics.json 두 개 모두 없음 — pipeline이 metrics 단계까지 도달 못 함)")
    sys.exit(0)
print(f"{'Metric':<28}{'P1 (H-Worst)':>18}{'P9 (H-Best)':>18}{'Δ (P9-P1)':>18}")
print("-" * 82)
keys = sorted({*(p1 or {}).keys(), *(p9 or {}).keys()})
for k in keys:
    a = (p1 or {}).get(k); b = (p9 or {}).get(k)
    if isinstance(a, (int, float)) and isinstance(b, (int, float)):
        print(f"{k:<28}{a:>18.4f}{b:>18.4f}{b-a:>18.4f}")
    else:
        print(f"{k:<28}{str(a):>18}{str(b):>18}{'-':>18}")
PY

green "Pilot driver 완료."
