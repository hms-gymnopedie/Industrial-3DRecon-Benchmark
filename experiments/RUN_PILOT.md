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

### 3.1 사용자 video-to-image 모듈 기능 (사전 통합)

본 pilot 에서 사용하는 사용자 video-to-image 전처리 모듈은 PAPER §3.2 의 4 sub-stage 를 사전 통합한 단일 도구이다:

| Sub-stage | 기능 | PAPER §3.2 매핑 |
|---|---|---|
| (1) | **비디오 불러오기** | input — raw bodycam video |
| (2) | **Frame 나누기** | (a) FPS-based frame extraction |
| (3) | **Blur 자동삭제** | (b) Laplacian variance 기반 sharpness threshold |
| (4) | **유사도 기준 중복제거** | (c) similarity-based deduplication |
| (5) | **Masking 처리** | (d) SAM2 / YOLOv8-seg instance mask |

따라서 본 pilot 의 docker 컨테이너 내부에서는 §3.2 의 4 sub-stage 를 *재실행하지 않으며*, 사용자 모듈 출력 (sharp + mask) 을 그대로 P1 / P9 의 학습 입력으로 사용한다.

### 3.2 사용자 모듈 출력 layout

site/run 아래 `sharp/` (RGB frame) + `mask/` (dynamic instance mask) 두 sub-folder 로 분리 출력:

```
${RAW_FRAMES}/{site}/{run}/sharp/*.png   ← 학습 입력 frame (blur 제거 + dedup 통과)
${RAW_FRAMES}/{site}/{run}/mask/*.png    ← sharp 와 1:1 매칭되는 dynamic instance mask
```

### 3.3 Sharp JPG → PNG 정규화 (필요 시 1회)

사용자 video-to-image 모듈이 sharp 를 JPG, mask 를 PNG 로 출력하는 경우 sharp 도 PNG 로 통일한다 (mask 는 이미 PNG 면 skip). 이유: (i) `mast3r_slam_to_colmap.py` 와 `reorganize_frames.sh` 의 PNG-only glob 호환, (ii) PSNR/SSIM noise floor 의 JPEG-artifact-induced underestimate 제거, (iii) §3.6 F3 fairness 일관성 (`data/README.md` §5 PNG lossless 정책).

```bash
# Option A — ImageMagick mogrify (가장 빠름, 권장 — apt install imagemagick)
for SITE in I-1 I-2 I-3 L-1 L-2 L-3; do
    SHARP_DIR="${RAW_FRAMES}/${SITE}/run-01/sharp"
    [ -d "${SHARP_DIR}" ] || continue
    cd "${SHARP_DIR}"
    n_jpg=$(ls *.jpg 2>/dev/null | wc -l)
    [ "${n_jpg}" -eq 0 ] && continue
    echo "[${SITE}] ${n_jpg} JPG → PNG"
    mogrify -format png *.jpg
    rm -f *.jpg
done
```

```bash
# Option B — Python PIL (ImageMagick 부재 시; Pillow 만 필요)
python3 <<'EOF'
import os, glob
from PIL import Image
RAW = os.environ.get("RAW_FRAMES", "/data/minsuh/raw_frames")
for site in ["I-1","I-2","I-3","L-1","L-2","L-3"]:
    sharp_dir = f"{RAW}/{site}/run-01/sharp"
    if not os.path.isdir(sharp_dir): continue
    n = 0
    for jpg in sorted(glob.glob(f"{sharp_dir}/*.jpg")):
        png = jpg.rsplit(".",1)[0] + ".png"
        if not os.path.exists(png):
            Image.open(jpg).save(png, "PNG", compress_level=1)
            n += 1
        os.remove(jpg)
    print(f"  [{site}] {n} files converted")
EOF
```

검증:
```bash
for SITE in I-1 I-2 I-3 L-1 L-2 L-3; do
    NS=$(ls "${RAW_FRAMES}/${SITE}/run-01/sharp"/*.png 2>/dev/null | wc -l)
    NM=$(ls "${RAW_FRAMES}/${SITE}/run-01/mask"/*.png 2>/dev/null | wc -l)
    LEFT_JPG=$(ls "${RAW_FRAMES}/${SITE}/run-01/sharp"/*.jpg 2>/dev/null | wc -l)
    echo "  ${SITE}: sharp_png=${NS}, mask_png=${NM}, leftover_jpg=${LEFT_JPG}"
done
# leftover_jpg 는 모두 0 이어야 함
```

비용: ImageMagick 기준 6 site ~5-10 min, 디스크 ~2-3× 증가 (1,500 frame × 6 site × 1920×1080 기준 ~5 GB JPG → ~15 GB PNG). PIL 옵션은 ~20-30 min.

### 3.4 ARS layout symlink 변환

ARS 표준 layout 으로 symlink (sharp → `frames/`, mask → `masks/`):

```bash
bash experiments/scripts/reorganize_frames.sh \
    --src   "${RAW_FRAMES}" \
    --dest  "${DATA_ROOT}" \
    --sites "I-1 I-2 I-3 L-1 L-2 L-3" \
    --runs  "run-01" \
    --mode  symlink

# 결과:
#   ${DATA_ROOT}/sites/{site}/runs/{run}/frames/*.png   (sharp 와 mapping)
#   ${DATA_ROOT}/sites/{site}/runs/{run}/masks/*.png    (mask 와 mapping)
# dry-run plan 확인: 위 명령에 --dry-run 추가
```

### 3.5 Mask 사용 정책

- P1 / P9 의 *primary 학습 입력은 frames/ 만* 사용 (mask 미참조)
- masks/ 는 §4.5e cluster B.1 ablation (mask on/off condition) 분기에서만 활성화
- 사용자 측에 mask 폴더가 없는 site/run 이 있으면 자동 skip (warning 만 출력). frames/ 는 단독으로도 P1/P9 실행 가능.
- 사용자 video-to-image 모듈이 §3.2 의 sub-stage (a)–(d) 4단계를 사전 통합한 상태이므로 PAPER §3.2 의 docker 내부 전처리 재실행은 본 pilot 에서 skip.

### 3.6 Frame budget 확인 (§3.6 F4)

§3.6 F4 의 frame budget (N_frames = 1,500) 은 *dedup 통과 후 effective frame 수* 로 정의. site 별 sharp/ 폴더의 PNG 수를 확인하여 정규화:

```bash
for SITE in I-1 I-2 I-3 L-1 L-2 L-3; do
    N=$(find "${RAW_FRAMES}/${SITE}/run-01/sharp" -name "*.png" 2>/dev/null | wc -l)
    echo "  ${SITE}: N_frames = ${N}"
done
```

| 결과 | 처리 |
|---|---|
| N ≥ 1,500 | 등간격 sub-sample 로 1,500 frame trim (run_pipeline_*.sh 내부 자동) |
| N < 1,500 | dense temporal resampling 으로 1,500 frame 충전 (run_pipeline_*.sh 내부) |
| N << 1,500 (e.g., < 500) | 사용자 video-to-image 모듈의 dedup threshold 가 과도 — 재추출 권장 |

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
