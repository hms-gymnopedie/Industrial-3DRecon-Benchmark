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

## 3. Raw frames → ARS layout 재배치 (hardlink)

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

### 3.3 Sharp 입력 포맷 — PNG 통일 (사용자 책임 사전 처리)

**정책:** 사용자 video-to-image 모듈의 sharp 출력이 JPG 인 경우 RAW_FRAMES 적재 *이전* 에 PNG 로 일괄 변환되어 있어야 한다. Mask 는 binary mask 이므로 PNG 만 허용 (lossless 필수).

**근거:**
- `mast3r_slam_to_colmap.py::list_frames()` 와 `reorganize_frames.sh` 가 PNG-only glob 매칭 (JPG 는 자동 skip)
- PSNR/SSIM noise floor 의 JPEG-artifact-induced underestimate 제거 (§4.3 Tab. 2 절대값 정확성)
- §3.6 F3 fairness 일관성 (data/README.md §5 PNG lossless 정책)
- §4.5d cluster A.3 오염 ablation 의 JPEG block artifact 혼동 차단

**Sharp / Mask 관계:** sharp 가 학습 입력의 primary set, mask 는 advisory 부가정보. 두 폴더는 *독립 collection* 으로 다루며 카운트 / 부분집합 관계는 강제하지 않는다 — (i) `skip_empty` 정책 (PAPER §3.2 (d)) 으로 mask 가 일부 frame 에만 생성될 수 있고 (`len(mask) < len(sharp)`), (ii) 사용자가 dashboard 또는 수동으로 sharp 의 불필요 frame 을 제거한 경우 그에 대응하는 mask 가 orphan 으로 남아 있을 수 있다 (`mask` 에 `sharp` 에 없는 파일명 존재 가능). 본 두 경우 모두 정상 상태이며 §4.5e ablation 은 `sharp ∩ mask` intersection 만 evidence 집합으로 사용한다 (PAPER §4.5e 정의).

**RAW_FRAMES 적재 후 검증 (필수):**
```bash
for SITE in I-1 I-2 I-3 L-1 L-2 L-3; do
    SHARP_DIR="${RAW_FRAMES}/${SITE}/run-01/sharp"
    MASK_DIR="${RAW_FRAMES}/${SITE}/run-01/mask"
    NS=$(ls "${SHARP_DIR}"/*.png 2>/dev/null | wc -l)
    NM=$(ls "${MASK_DIR}"/*.png  2>/dev/null | wc -l)
    LEFT_JPG=$(ls "${SHARP_DIR}"/*.jpg 2>/dev/null | wc -l)
    if [ "${LEFT_JPG}" -eq 0 ] && [ "${NS}" -gt 0 ]; then
        echo "  ${SITE}: sharp=${NS} (PNG), mask=${NM} (advisory) ✓"
    else
        echo "  ${SITE}: sharp=${NS}, mask=${NM}, leftover_jpg=${LEFT_JPG} — sharp 측 검토 필요"
    fi
done
```

두 조건만 만족하면 §3.4 진입:
- `leftover_jpg = 0` (모든 sharp 가 PNG — `mast3r_slam_to_colmap.py::list_frames()` 의 PNG-only glob 호환)
- `sharp ≥ 1` (frame 존재)

Mask count / orphan 여부는 검증하지 않는다 — §4.5e ablation 이 intersection 만 사용하므로 mismatch 가 있어도 자동 정합.

### 3.4 ARS layout 변환 (hardlink default)

ARS 표준 layout 으로 hardlink 변환 (sharp → `frames/`, mask → `masks/`). **default mode 는 `hardlink`** — symlink 는 docker bind mount 시 container 내부에서 target prefix 가 안 보여 broken 됨 (실제 pilot 환경에서 검증). raw 와 dest 가 *동일 filesystem* 일 때 hardlink 가 가장 안전 (디스크 추가 0 + docker 호환).

**`--src` / `--dest` 의 의미:**

| Flag | 의미 | 예시 값 |
|---|---|---|
| `--src` | 사용자 video-to-image 모듈이 PNG 를 저장한 root (각 site/run 의 `sharp/` + `mask/` sub-folder 가 이 아래에 위치) | `/data/minsuh/raw_frames` |
| `--dest` | ARS data root (변환 결과 `sites/{site}/runs/{run}/{frames,masks}/` 가 이 아래에 생성) | `/data/minsuh/experiment/data` |

**예시 — 절대 경로로 바로 실행:**

```bash
bash experiments/scripts/reorganize_frames.sh \
    --src   /data/minsuh/raw_frames \
    --dest  /data/minsuh/experiment/data \
    --sites "I-1 I-2 I-3 L-1 L-2 L-3" \
    --runs  "run-01" \
    --mode  hardlink
```

**또는 §1 의 환경 변수 사용:**

```bash
bash experiments/scripts/reorganize_frames.sh \
    --src   "${RAW_FRAMES}" \
    --dest  "${DATA_ROOT}" \
    --sites "I-1 I-2 I-3 L-1 L-2 L-3" \
    --runs  "run-01" \
    --mode  hardlink

# 결과:
#   ${DATA_ROOT}/sites/{site}/runs/{run}/frames/*.png   (sharp 와 mapping, hardlink)
#   ${DATA_ROOT}/sites/{site}/runs/{run}/masks/*.png    (mask 와 mapping, hardlink)
# dry-run plan 확인: 위 명령에 --dry-run 추가
```

**Mode 선택 가이드:**

| Mode | 사용 시점 | 디스크 | docker bind mount 호환 |
|---|---|---|---|
| `hardlink` (default) | raw 와 dest 가 **동일 filesystem** 일 때 (가장 흔한 경우) | 추가 0 | ✓ |
| `symlink` | raw 와 dest 가 다른 FS 인데 docker 미사용 시 | 추가 0 | ✗ docker bind 시 broken |
| `rsync` | raw 와 dest 가 다른 FS + docker 사용 시 | ~2× | ✓ |
| `mv` | 원본 보존 불필요 시 (가급적 사용 X) | 절약 | ✓ |

스크립트가 `hardlink` 선택 시 src/dest 의 mount point 를 자동 비교 → 다른 FS 면 fatal 종료 + `rsync` 권장 메시지 출력.

**구체 예시 — I-1 site 의 before / after.**

변환 전 (raw 원본):
```
/data/minsuh/raw_frames/I-1/run-01/
├── sharp/
│   ├── 000001.png      # 사용자 모듈이 추출한 sharp frame (PNG 통일 후)
│   ├── 000002.png
│   ├── 000003.png
│   ├── ...
│   └── 001500.png
└── mask/
    ├── 000001.png      # dynamic instance 검출된 frame 의 binary exclusion mask
    ├── 000005.png      # 000002~000004 는 skip_empty 로 mask 미생성
    ├── 000007.png
    ├── ...
    └── 001498.png
```

변환 후 (ARS layout — 모든 파일이 symlink, 디스크 추가 사용 0):
```
/data/minsuh/experiment/data/sites/I-1/runs/run-01/
├── frames/
│   ├── 000001.png → /data/minsuh/raw_frames/I-1/run-01/sharp/000001.png
│   ├── 000002.png → /data/minsuh/raw_frames/I-1/run-01/sharp/000002.png
│   ├── 000003.png → /data/minsuh/raw_frames/I-1/run-01/sharp/000003.png
│   ├── ...
│   └── 001500.png → /data/minsuh/raw_frames/I-1/run-01/sharp/001500.png
└── masks/
    ├── 000001.png → /data/minsuh/raw_frames/I-1/run-01/mask/000001.png
    ├── 000005.png → /data/minsuh/raw_frames/I-1/run-01/mask/000005.png
    ├── 000007.png → /data/minsuh/raw_frames/I-1/run-01/mask/000007.png
    ├── ...
    └── 001498.png → /data/minsuh/raw_frames/I-1/run-01/mask/001498.png
```

본 예시에서 `frames/` 는 1,500개, `masks/` 는 (예: 380개) — 두 폴더는 독립 collection (§3.2 (d)). intersection 만 §4.5e ablation evidence 로 사용.

검증 (변환 직후):
```bash
# I-1 frames symlink 첫 3개 확인 — 모두 raw_frames 의 sharp 로 향해야 함
ls -la ${DATA_ROOT}/sites/I-1/runs/run-01/frames | head -5
# 예상:
#   lrwxr-xr-x  ...  000001.png -> /data/minsuh/raw_frames/I-1/run-01/sharp/000001.png
#   lrwxr-xr-x  ...  000002.png -> /data/minsuh/raw_frames/I-1/run-01/sharp/000002.png
#   ...

# I-1 masks symlink 첫 3개 확인 — 모두 raw_frames 의 mask 로 향해야 함
ls -la ${DATA_ROOT}/sites/I-1/runs/run-01/masks | head -5
# 예상:
#   lrwxr-xr-x  ...  000001.png -> /data/minsuh/raw_frames/I-1/run-01/mask/000001.png
#   lrwxr-xr-x  ...  000005.png -> /data/minsuh/raw_frames/I-1/run-01/mask/000005.png
#   ...

# Broken symlink (target 누락) 검출 — 0 이어야 함
find ${DATA_ROOT}/sites -type l ! -exec test -e {} \; -print | wc -l
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
    ars/m1_colmap:3.9.1 \
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
        ars/m1_colmap:3.9.1 \
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

## 10. Multi-server setup (image distribution + GPU 점유 처리)

학교 GPU 클러스터 등 다중 host 환경에서 build 반복 없이 image 를 전송하는 절차 + GPU 점유 변동 대응.

### 10.1 Docker image 전송 (build 1회 → 모든 host 에 배포)

**기존 build 완료 서버에서 4 image export:**
```bash
mkdir -p /data/minsuh/docker_images
docker save ars/m1_colmap:3.9.1 \
            ars/m7_mast3r_slam:latest \
            ars/m8_3dgs:latest \
            ars/m9_2dgs:latest \
  | gzip > /data/minsuh/docker_images/ars_all.tar.gz
ls -lh /data/minsuh/docker_images/ars_all.tar.gz   # 예상 ~8–15 GB
```

**새 서버에서 import:**
```bash
# NFS 공유 시 — 같은 경로에서 load
docker load < /data/minsuh/docker_images/ars_all.tar.gz

# NFS 미공유 시 — scp 후 load
scp big-rodin1:/data/minsuh/docker_images/ars_all.tar.gz /data/minsuh/docker_images/
docker load < /data/minsuh/docker_images/ars_all.tar.gz

# 검증
docker images | grep "ars/"
bash experiments/scripts/verify_dockers.sh --skip-build   # smoke test 만
```

새 서버에서 처음 진입 시 build 반복 (~50–75 min) 회피. 같은 hardware class (RTX 4090 + CUDA 11.8) 라면 image 호환 완전.

### 10.2 GPU 점유 변동 — manual flag

```bash
# Free GPU 확인 (memory.used < 100 MiB)
nvidia-smi --query-gpu=index,memory.used,memory.total,utilization.gpu --format=csv,noheader

# 시나리오별 명령
# (a) 2 GPU 모두 free
bash run_pipeline_p1.sh --site I-1 --run run-01 \
    --data-root "${DATA_ROOT}" --gpu-pose 0 --gpu-rep 1   # default

# (b) GPU 0 점유, GPU 1 만 free (pose+rep sequential)
bash run_pipeline_p1.sh --site I-1 --run run-01 \
    --data-root "${DATA_ROOT}" --gpu-pose 1 --gpu-rep 1

# (c) GPU 1 점유, GPU 0 만 free
bash run_pipeline_p1.sh --site I-1 --run run-01 \
    --data-root "${DATA_ROOT}" --gpu-pose 0 --gpu-rep 0
```

Wall-time 영향 — 단일 GPU 시 pose+rep sequential 이라 ~2× wall-time 증가 (1 site P1 약 1–1.5 h → 약 2–3 h).

---

## 11. Troubleshooting

### 11.1 `[FATAL] frames 디렉토리에 PNG 없음` — symlink + docker mount 문제

증상: `bash run_pipeline_p1.sh` 가 `n_frames: 0` 출력하며 fatal. 그러나 host 측에서 `ls ${DATA_ROOT}/sites/${SITE}/runs/${RUN}/frames/` 확인 시 symlink 다수 존재.

원인: `frames/` 의 symlink target 이 docker container 내부에서 안 보임. `-v ${DATA_ROOT}:/data` 만 bind 되고 symlink target 의 raw root (예: `/data/minsuh/raw_frames`) 가 미bind. 또한 `find -type f` 가 symlink (`-type l`) 를 제외하여 host 측 frames count 도 0.

해결: hardlink mode 로 재변환 (§3.4 default). 1-shot 명령:
```bash
for SITE in I-1 I-2 I-3 L-1 L-2 L-3; do
    SRC=/data/minsuh/raw_frames/${SITE}/run-01/sharp
    DST=/data/minsuh/experiment/data/sites/${SITE}/runs/run-01/frames
    if [ -d "$SRC" ]; then
        rm -rf "$DST"; mkdir -p "$DST"
        for f in "$SRC"/*.png; do ln "$f" "$DST/$(basename "$f")"; done
        echo "  [${SITE}] frames hardlink: $(ls "$DST" | wc -l)"
    fi
    SRC_M=/data/minsuh/raw_frames/${SITE}/run-01/mask
    DST_M=/data/minsuh/experiment/data/sites/${SITE}/runs/run-01/masks
    if [ -d "$SRC_M" ]; then
        rm -rf "$DST_M"; mkdir -p "$DST_M"
        for f in "$SRC_M"/*.png; do ln "$f" "$DST_M/$(basename "$f")"; done
        echo "  [${SITE}] masks  hardlink: $(ls "$DST_M" | wc -l)"
    fi
done
```

또는 reorganize_frames.sh 를 `--mode hardlink` 로 재실행 (동일 결과).

### 11.2 `Colmap camera model not handled: only undistorted datasets (PINHOLE or SIMPLE_PINHOLE cameras) supported!`

증상: P1 Stage 2 (M8 3DGS) 또는 P9 Stage 3 (M9 2DGS) 의 `dataset_readers.py` 에서 `AssertionError: Colmap camera model not handled` 발생.

원인: COLMAP `--camera_model OPENCV` (또는 adapter 의 OPENCV text 산출) 가 3DGS/2DGS 의 `readColmapCameras` 가 거부하는 model — 3DGS upstream 이 PINHOLE / SIMPLE_PINHOLE 만 지원.

해결 — 영구 fix 완료 (`git pull` 후 재실행):
- `run_pipeline_p1.sh` 에 **Stage 1.5 (image_undistorter)** 추가 — Stage 1 (COLMAP) 후 OPENCV → PINHOLE + undistorted images 변환
- `run_pipeline_p9.sh` 에 **Stage 2.5 (image_undistorter)** 추가 — Stage 2 (adapter) 후 동일 변환
- 3DGS / 2DGS 의 `--source_path` 가 `pose_undistorted/` 로 자동 변경

이미 Stage 1 (COLMAP) 또는 Stage 2 (adapter) 가 끝난 상태에서 재실행 시 — skip-flag 로 이전 stage 건너뜀:
```bash
# P1 — Stage 1 종료, Stage 1.5 부터 진행
bash run_pipeline_p1.sh --site I-1 --run run-01 \
    --data-root /data/minsuh/experiment/data --skip-pose

# P9 — Stage 1·2 종료, Stage 2.5 부터 진행
bash run_pipeline_p9.sh --site I-1 --run run-01 \
    --data-root /data/minsuh/experiment/data \
    --weights /data/minsuh/experiment/weights \
    --skip-pose --skip-adapt
```

Stage 1.5 / 2.5 는 idempotent — `pose_undistorted/sparse/cameras.{bin,txt}` 이미 존재 시 자동 skip.

### 11.3 `pull access denied for ars/...` — image 미존재

새 서버에서 `verify_dockers.sh --skip-build` 실행 시 image pull 실패. 원인 — image 가 local-only (registry 미등록), `--skip-build` 로 build 도 안 함.

해결:
- **옵션 A:** build 새로 실행 — `bash verify_dockers.sh` (--skip-build 제거, ~50–75 min)
- **옵션 B:** 기존 서버에서 export → 새 서버 import (§10.1)

### 11.4 Diagnostic 1-shot — frames 디렉토리 상태 점검

`run_pipeline_p1.sh` fail 시 가장 먼저 실행:
```bash
DR=/data/minsuh/experiment/data
SITE=I-1
RUN=run-01

echo "=== (1) ARS layout 디렉토리 ==="
ls -la "${DR}/sites/${SITE}/runs/${RUN}/" | head -10

echo "=== (2) frames/ 내부 ==="
ls -la "${DR}/sites/${SITE}/runs/${RUN}/frames/" | head -10

echo "=== (3) Broken symlink ==="
find "${DR}/sites/${SITE}/runs/${RUN}/frames" -type l ! -exec test -e {} \; -print | head -5

echo "=== (4) Raw source 확인 ==="
for SRC in /data/minsuh/raw_frames/${SITE}/${RUN}/sharp \
           /scratch/minsuh/raw_frames/${SITE}/${RUN}/sharp; do
    if [ -d "${SRC}" ]; then
        echo "  ✓ ${SRC}: png=$(ls ${SRC}/*.png 2>/dev/null | wc -l)"
    else
        echo "  ✗ ${SRC}: 없음"
    fi
done
```

해석:
- (1) `frames/` 폴더 미존재 → §3.4 reorganize 실행
- (2) 비어있음 → §11.1 hardlink 재변환
- (3) broken (red color) → §11.1 hardlink 재변환
- (4) png=0 모두 → raw frames 미적재 (사용자 측 video-to-image 모듈 출력 확인)

---

## 12. Cross-reference

- 어댑터: [`adapters/colmap_to_intrinsics.py`](adapters/colmap_to_intrinsics.py) · [`adapters/mast3r_slam_to_colmap.py`](adapters/mast3r_slam_to_colmap.py)
- 파이프라인 wrapper: [`scripts/run_pipeline_p1.sh`](scripts/run_pipeline_p1.sh) · [`scripts/run_pipeline_p9.sh`](scripts/run_pipeline_p9.sh) · [`scripts/run_pilot_i1.sh`](scripts/run_pilot_i1.sh)
- 데이터 layout 규약: [`data/README.md`](data/README.md)
- 본문 가설/표 매핑: [PAPER_OUTLINE.md §3.3 Table 1b](../PAPER_OUTLINE.md)
