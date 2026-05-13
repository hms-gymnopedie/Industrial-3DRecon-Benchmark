# RUN_PILOT.md — P1/P9 학교 서버 실행 지침

> 학교 서버 (RTX 4090 × 2 호스트 × 2 GPU) 환경에서 `/data/minsuh/experiment/` 경로로 P1 / P9 pilot 을 실행하는 single-page 가이드.

---

## 0. 사전 확인

```bash
# 환경 검증 (이미 완료된 경우 skip)
bash experiments/scripts/verify_gpu.sh
bash experiments/scripts/verify_dockers.sh --skip-build   # 4 image smoke test
ls experiments/weights/MASt3R_*.pth                       # checkpoint 존재 확인
```

학교 서버에 docker image (ars/m1_colmap, m7_mast3r_slam, m8_3dgs, m9_2dgs) 가 빌드/푸시되어 있어야 함. 빌드 명령은 [`scripts/README.md`](scripts/README.md) §1.1 참조.

---

## 1. 경로 변수 일괄 설정

```bash
# 환경 변수 — 학교 서버 진입 후 매 세션 export
export EXP_ROOT=/data/minsuh/experiment        # 모든 데이터/출력의 루트
export DATA_ROOT=${EXP_ROOT}/data              # data/sites/ + data/outputs/
export WEIGHTS_DIR=${EXP_ROOT}/weights         # MASt3R checkpoint
export RAW_FRAMES=/data/minsuh/raw_frames      # 사용자 video-to-image 추출 결과

# scratch 사용 회피 — 본 export 가 모든 docker bind mount source 의 prefix
mkdir -p "${DATA_ROOT}" "${WEIGHTS_DIR}"
```

> **/scratch → /data migration 시 주의:** 본 repo 의 모든 pipeline / verify 스크립트는 `--data-root` / `--weights` / `--dest` 플래그로 path 를 외부 주입한다. 코드 수정 없이 `${EXP_ROOT}` 변경만으로 path 이동이 완료됨.

---

## 2. Weights 다운로드 (한 번만)

```bash
bash experiments/scripts/download_weights.sh --dest "${WEIGHTS_DIR}"
# 결과: ${WEIGHTS_DIR}/MASt3R_ViTLarge_BaseDecoder_512_catmlpdpt_metric.pth
```

---

## 3. Raw frames → ARS layout 재배치 (symlink)

사용자 video-to-image 모듈로 추출된 PNG (`${RAW_FRAMES}/{site}/{run}/*.png`) 를 ARS 표준 layout 으로 symlink 변환.

```bash
bash experiments/scripts/reorganize_frames.sh \
    --src   "${RAW_FRAMES}" \
    --dest  "${DATA_ROOT}" \
    --sites "I-1 I-2 I-3 L-1 L-2 L-3" \
    --runs  "run-01" \
    --mode  symlink

# 결과: ${DATA_ROOT}/sites/{site}/runs/{run}/frames/*.png  (각 PNG 는 symlink)
# dry-run plan 확인: 위 명령에 --dry-run 추가
```

---

## 4. P1 (H-Worst) 실행 — I-1 site

```bash
bash experiments/scripts/run_pipeline_p1.sh \
    --site I-1 --run run-01 --iterations 30000 \
    --data-root "${DATA_ROOT}" \
    --gpu-pose 0 --gpu-rep 1

# 결과:
#   ${DATA_ROOT}/outputs/P1/I-1/run-01/pose/sparse/0/{cameras,images,points3D}.bin
#   ${DATA_ROOT}/outputs/P1/I-1/run-01/recon/point_cloud/iteration_30000/point_cloud.ply
#   ${DATA_ROOT}/outputs/P1/I-1/run-01/metrics.json
```

**P1 stage 1 (COLMAP) 종료 직후, site 공유 intrinsics 추출:**

```bash
docker run --rm \
    -v "${DATA_ROOT}":/data \
    -v "$(pwd)/experiments/adapters":/adapters \
    ars/m1_colmap:latest \
    python /adapters/colmap_to_intrinsics.py \
        --cameras /data/outputs/P1/I-1/run-01/pose/sparse/0/cameras.bin \
        --output  /data/sites/I-1/calib/intrinsics.json
```

(P9 의 MASt3R-SLAM → COLMAP 어댑터가 본 JSON 을 자동 참조한다.)

---

## 5. P9 (H-Best) 실행 — I-1 site

```bash
bash experiments/scripts/run_pipeline_p9.sh \
    --site I-1 --run run-01 --iterations 30000 \
    --data-root "${DATA_ROOT}" \
    --weights   "${WEIGHTS_DIR}" \
    --gpu-pose 0 --gpu-rep 1

# 결과:
#   ${DATA_ROOT}/outputs/P9/I-1/run-01/pose_native/trajectory.txt   # MASt3R-SLAM native
#   ${DATA_ROOT}/outputs/P9/I-1/run-01/pose/sparse/0/*.txt          # COLMAP-format text
#   ${DATA_ROOT}/outputs/P9/I-1/run-01/recon/point_cloud/iteration_30000/point_cloud.ply
#   ${DATA_ROOT}/outputs/P9/I-1/run-01/metrics.json
```

---

## 6. 병렬 실행 (4 GPU 가용 시) — single-host 또는 two-host

### 6.1 Single-host (4 GPU 한 서버에 모임)

```bash
bash experiments/scripts/run_pilot_i1.sh \
    --site I-1 --run run-01 \
    --single-host \
    --data-root "${DATA_ROOT}" \
    --weights   "${WEIGHTS_DIR}"
# P1 (GPU 0/1) + P9 (GPU 2/3) 동시 실행, compare summary 출력
```

### 6.2 Two-host (서버 A: P1, 서버 B: P9)

```bash
# 서버 A
bash experiments/scripts/run_pilot_i1.sh --only p1 \
    --site I-1 --run run-01 \
    --data-root "${DATA_ROOT}"

# 서버 B (병렬, 같은 ${DATA_ROOT} 가 공유 스토리지인 경우)
bash experiments/scripts/run_pilot_i1.sh --only p9 \
    --site I-1 --run run-01 \
    --data-root "${DATA_ROOT}" \
    --weights   "${WEIGHTS_DIR}"
```

---

## 7. 6 site 일괄 (pilot 검증 후)

```bash
for SITE in I-1 I-2 I-3 L-1 L-2 L-3; do
    bash experiments/scripts/run_pipeline_p1.sh \
        --site "${SITE}" --run run-01 \
        --data-root "${DATA_ROOT}"
done

# P1 결과 6 site 의 intrinsics 추출
for SITE in I-1 I-2 I-3 L-1 L-2 L-3; do
    docker run --rm \
        -v "${DATA_ROOT}":/data \
        -v "$(pwd)/experiments/adapters":/adapters \
        ars/m1_colmap:latest \
        python /adapters/colmap_to_intrinsics.py \
            --cameras /data/outputs/P1/${SITE}/run-01/pose/sparse/0/cameras.bin \
            --output  /data/sites/${SITE}/calib/intrinsics.json
done

# 그 후 P9 일괄 (병렬 권장)
for SITE in I-1 I-2 I-3 L-1 L-2 L-3; do
    bash experiments/scripts/run_pipeline_p9.sh \
        --site "${SITE}" --run run-01 \
        --data-root "${DATA_ROOT}" \
        --weights   "${WEIGHTS_DIR}"
done
```

---

## 8. 결과 수집 / 논문 반영

```bash
# 6 site × 2 config (P1, P9) = 12 metrics.json 수집
find "${DATA_ROOT}/outputs" -name "metrics.json" | sort

# 본문 (PAPER_DRAFT.md) §4.3 Table 2 의 TBD 셀 → 실측값 대체
# (수동 patch — PSNR/SSIM/LPIPS/wall_time/n_gaussians 등)
```

PAPER_DRAFT.md Table 2 의 P1 / P9 column 을 우선 fill 후, 나머지 P2–P8 은 후속 site 실행 시 추가.

---

## 9. Wall-time 예상

| 단계 | per site | 6 site 합 (sequential) |
|---|---|---|
| P1 M1 COLMAP self-calib | 30–60 min | 3–6 h |
| P1 M8 3DGS (30k iter) | 30–45 min | 3–4.5 h |
| P9 M7 MASt3R-SLAM | 10–20 min | 1–2 h |
| P9 M9 2DGS (30k iter) | 30–60 min | 3–6 h |
| **P1 6-site sequential** | — | **6–10 h** |
| **P9 6-site sequential** | — | **4–8 h** |
| **P1 + P9 single-host parallel (4 GPU)** | — | **6–10 h** (P9 가 P1 의 wall-clock 내 완료) |
| **P1 + P9 two-host parallel** | — | **3–5 h** |

---

## 10. Cross-reference

- 어댑터: [`adapters/colmap_to_intrinsics.py`](adapters/colmap_to_intrinsics.py) · [`adapters/mast3r_slam_to_colmap.py`](adapters/mast3r_slam_to_colmap.py)
- 파이프라인 wrapper: [`scripts/run_pipeline_p1.sh`](scripts/run_pipeline_p1.sh) · [`scripts/run_pipeline_p9.sh`](scripts/run_pipeline_p9.sh) · [`scripts/run_pilot_i1.sh`](scripts/run_pilot_i1.sh)
- 데이터 layout 규약: [`data/README.md`](data/README.md)
- 본문 가설/표 매핑: [PAPER_OUTLINE.md §3.3 Table 1b](../PAPER_OUTLINE.md)
