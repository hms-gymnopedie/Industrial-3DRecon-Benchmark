# Pipeline Flow — P1, P9 정확한 stage 실행 흐름 + P2–P8 구현 상태

> 본 문서는 사용자 질문 3건에 대한 정식 답변이자, 본 repository 의 *현재 시점 실험 범위* 의 명세이다.
> - §1: P1 / P9 의 의미 (사전등록 가설 + Table 1b 매핑)
> - §2: P1 (H-Worst) end-to-end flow — `run_pipeline_p1.sh` 코드 기준
> - §3: P9 (H-Best) end-to-end flow — `run_pipeline_p9.sh` 코드 기준
> - §4: P2–P8 의 구현 상태 (사전등록 가설만 — 실험 deferred)
> - §5: PAPER 본문에서 어떻게 다뤄지는지 + Tier 3 진입 조건
>
> Cross-reference: [PAPER_OUTLINE §3.3 Table 1b](../PAPER_OUTLINE.md) / [PAPER_DRAFT §1.4 사전등록 가설](../PAPER_DRAFT.md) / [`scripts/run_pipeline_p1.sh`](scripts/run_pipeline_p1.sh) / [`scripts/run_pipeline_p9.sh`](scripts/run_pipeline_p9.sh).

---

## 1. P1 / P9 의 의미 — 사전등록 가설의 두 극단

본 논문은 9 atomic methods × 4 계열 (SfM / learning matching / deep SLAM / 3D representation) 중에서 **9 pipeline configurations (P1–P9)** 를 budget-aware subset 으로 정의 ([PAPER §3.3 Table 1b](../PAPER_OUTLINE.md)). P1 과 P9 는 *그 9 configurations 의 양극단* 이다.

### 1.1 P1 = H-Worst (사전등록 최하위)

| 구성 | Method | 계열 | 역할 |
|---|---|---|---|
| Stage 1 (pose) | **M1 COLMAP** [1] | SfM (hand-crafted) | SIFT keypoint + incremental BA — 카메라 외부 파라미터 + sparse 3D points |
| Stage 2 (rep) | **M8 3DGS** [8] | Volumetric representation | anisotropic 3D Gaussian 학습 (~30,000 iter) |

**사전등록 가설 H-Worst:** P1 (= COLMAP + 3DGS) 가 9 configurations 중 산업현장 도메인 종합 ranking *최하위*. 산업현장의 cluster A (textureless / reflective / 오염) · cluster B.1 (작업자 동선) · cluster C (저조도 · 비균질 조명) 모두에서 SIFT keypoint repeatability 가 붕괴되고, 3DGS 의 anisotropic 표현은 planar dominant 환경에서 over-parameterized → BEV occupancy false-positive 증가 → navigation 성공률 ↓.

### 1.2 P9 = H-Best (사전등록 최상위)

| 구성 | Method | 계열 | 역할 |
|---|---|---|---|
| Stage 1 (pose) | **M7 MASt3R-SLAM** [7] | Deep SLAM (with prior) | MASt3R dense matching prior 결합 SLAM — pose + native pointmap |
| Stage 2 (adapter) | `mast3r_slam_to_colmap.py` | Format conversion | TUM trajectory → COLMAP text format (quaternion 순서 + pose 방향 reversal) |
| Stage 3 (rep) | **M9 2DGS** [9] | Surface representation (planar prior) | surface-aligned 2D oriented disk 학습 (~30,000 iter) + native TSDF mesh 추출 |

**사전등록 가설 H-Best:** P9 (= MASt3R-SLAM + 2DGS) 가 9 configurations 중 산업현장 도메인 종합 ranking *최상위*. Deep matching prior 가 cluster A/B/C 의 SIFT failure modes 를 우회하고, 2DGS 의 planar prior 가 산업현장 dominant geometry (벽 · 바닥 · 기계 외관) 와 정합 → mesh extraction 의 TSDF fusion 이 native 하게 작동 → BEV IoU ↑ → navigation 성공률 ↑.

### 1.3 두 가설의 Δ — H-Gap 의 reference pair

P1 ↔ P9 의 metric 차이 (Δ) 가 산업현장에서 더 크고, library control 에서 더 작다는 가설이 **H-Gap**: `Δ_industrial > Δ_library` (95% block bootstrap CI 가 0 을 포함하지 않음 → supported). 본 비교가 본 논문의 핵심 falsifiable framework 이며, 가설 검정 시점에서 P1·P9 두 configuration 만 *반드시* 모든 6 site 에서 실행되어야 한다 ([PAPER §4.4](../PAPER_DRAFT.md) 참조).

---

## 2. P1 (H-Worst) end-to-end flow — `run_pipeline_p1.sh`

총 3 stage. 사전등록 가설 H-Worst 검증의 primary 입력. Wall-time per site 약 60–105 분 (4090 1 GPU 기준).

### 2.1 Stage 0 — Pre-flight 검증

`run_pipeline_p1.sh` line 65–86:

```bash
# 입력 확인
ls ${DATA_ROOT}/sites/${SITE}/runs/${RUN}/frames/*.png   # ≥1 개
```

| 항목 | 검증 |
|---|---|
| `frames/` 디렉토리 존재 | `[FATAL] frames 디렉토리 없음` 시 — `data/README.md §5` 확인 |
| PNG 파일 수 ≥ 1 | `find -maxdepth 1 -type f -name '*.png'` (hardlink/일반 file 만; symlink 는 [`§3.4`](RUN_PILOT.md) hardlink mode 로 변환 권장) |
| 출력 디렉토리 생성 | `pose/`, `recon/`, `logs/` 3 폴더 mkdir |

### 2.2 Stage 1 — M1 COLMAP automatic_reconstructor

`run_pipeline_p1.sh` line 88–113. GPU `--gpu-pose` (default 0).

**Docker call:**
```bash
docker run --rm --gpus "device=${GPU_POSE}" \
    -v ${DATA_ROOT}:/data \
    ars/m1_colmap:3.9.1 \
    colmap automatic_reconstructor \
        --image_path     /data/sites/${SITE}/runs/${RUN}/frames \
        --workspace_path /data/outputs/P1/${SITE}/${RUN}/pose \
        --camera_model OPENCV \
        --single_camera 1 \
        --sparse 1 --dense 0 \
        --use_gpu 1
```

**산출물:**
- `${OUT_DIR}/pose/sparse/0/cameras.bin` (또는 `.txt`) — OPENCV camera intrinsics (8-param)
- `${OUT_DIR}/pose/sparse/0/images.bin` — frame ↔ pose 매핑
- `${OUT_DIR}/pose/sparse/0/points3D.bin` — sparse 3D points
- `${LOG_DIR}/m1_colmap.log` — COLMAP stdout

**Sanity check:** `cameras.bin` 또는 `cameras.txt` 가 없으면 `[FATAL] sparse reconstruction 출력 누락` 으로 종료 (textureless 영역 registration 실패 시).

**Wall-time:** ~30–60 min per site (frame 1,500 기준).

### 2.3 Stage 2 — M8 3DGS train (volumetric representation)

`run_pipeline_p1.sh` line 127–151. GPU `--gpu-rep` (default 1).

**Docker call:**
```bash
docker run --rm --gpus "device=${GPU_REP}" \
    -v ${DATA_ROOT}:/data \
    ars/m8_3dgs:latest \
    python /opt/gaussian_splatting/train.py \
        --source_path /data/outputs/P1/${SITE}/${RUN}/pose \
        --images      /data/sites/${SITE}/runs/${RUN}/frames \
        --model_path  /data/outputs/P1/${SITE}/${RUN}/recon \
        --iterations  30000 \
        --resolution 1 \
        --eval
```

**산출물:**
- `${OUT_DIR}/recon/point_cloud/iteration_30000/point_cloud.ply` — 학습 완료 3DGS
- `${OUT_DIR}/recon/cameras.json` — 등록 view 수 + 카메라 정보
- `${OUT_DIR}/recon/results.json` — PSNR / SSIM / LPIPS (3DGS metrics.py 산출물; eval split)
- `${LOG_DIR}/m8_3dgs.log`

**Wall-time:** ~30–45 min per site.

### 2.4 Stage 3 — `compute_metrics.py` 집계

`run_pipeline_p1.sh` line 155–169. Host 측 Python 실행.

```bash
python3 compute_metrics.py \
    --pipeline P1 --site ${SITE} --run ${RUN} \
    --recon-dir ${OUT_DIR}/recon \
    --t-pose ${T_POSE} --t-rep ${T_REP} \
    --output ${OUT_DIR}/metrics.json
```

**산출물 `metrics.json` (구조):**
```json
{
  "pipeline": "P1",
  "site": "I-1", "run": "run-01",
  "wall_time_pose_sec": 1842, "wall_time_rep_sec": 1567,
  "wall_time_total_sec": 3409,
  "psnr": 23.4, "ssim": 0.812, "lpips": 0.182,
  "eval_iteration": 30000,
  "n_gaussians": 412381,
  "n_views_registered": 1487,
  "status": "ok"
}
```

본 metrics.json 은 [PAPER §4.3 Tab. 2](../PAPER_DRAFT.md) 의 P1 column 의 *TBD 수치 fill* 의 직접 입력.

### 2.5 P1 전체 flow 요약

```
[frames/*.png]
     │
     ▼
┌─────────────────────────────────────┐
│  Stage 1: M1 COLMAP (GPU 0)        │
│  automatic_reconstructor + OPENCV  │
└─────────────────────────────────────┘
     │
     ▼  pose/sparse/0/{cameras,images,points3D}.bin
┌─────────────────────────────────────┐
│  Stage 2: M8 3DGS (GPU 1)          │
│  train.py --iterations 30000       │
└─────────────────────────────────────┘
     │
     ▼  recon/point_cloud/iteration_30000/point_cloud.ply
┌─────────────────────────────────────┐
│  Stage 3: compute_metrics.py (host) │
│  PSNR/SSIM/LPIPS + wall-time        │
└─────────────────────────────────────┘
     │
     ▼
[metrics.json]
```

---

## 3. P9 (H-Best) end-to-end flow — `run_pipeline_p9.sh`

총 4 stage. 사전등록 가설 H-Best 검증의 primary 입력. Wall-time per site 약 40–95 분 (4090 1 GPU 기준; SLAM 빠름).

### 3.1 Stage 0 — Pre-flight 검증

`run_pipeline_p9.sh` line 75–103. P1 보다 검증 항목 2개 더 많음.

| 항목 | 검증 |
|---|---|
| `frames/` 디렉토리 + PNG ≥ 1 | (P1 와 동일) |
| `${SITE_DIR}/calib/intrinsics.json` | **필수** — P9 가 MASt3R-SLAM 의 intrinsics 입력으로 사용. 일반적으로 P1 의 COLMAP 결과를 `colmap_to_intrinsics.py` 로 추출 (decision α; [adapters/README.md §2](adapters/README.md)). |
| `${WEIGHTS_DIR}/MASt3R_ViTLarge_BaseDecoder_512_catmlpdpt_metric.pth` | MASt3R checkpoint — `download_weights.sh` 으로 사전 다운 |

### 3.2 Stage 1 — M7 MASt3R-SLAM (deep-prior visual SLAM)

`run_pipeline_p9.sh` line 105–131. GPU `--gpu-pose` (default 0).

**Docker call:**
```bash
docker run --rm --gpus "device=${GPU_POSE}" \
    -v ${DATA_ROOT}:/data \
    -v ${WEIGHTS_DIR}:/weights \
    ars/m7_mast3r_slam:latest \
    python /opt/mast3r_slam/main.py \
        --image_dir    /data/sites/${SITE}/runs/${RUN}/frames \
        --output_dir   /data/outputs/P9/${SITE}/${RUN}/pose_native \
        --checkpoint   /weights/MASt3R_ViTLarge_BaseDecoder_512_catmlpdpt_metric.pth \
        --intrinsics   /data/sites/${SITE}/calib/intrinsics.json \
        --device cuda:0
```

**산출물 (native):**
- `${OUT_DIR}/pose_native/trajectory.txt` — TUM format (`ts tx ty tz qx qy qz qw`)
- `${OUT_DIR}/pose_native/points.ply` (선택) — dense pointmap
- `${LOG_DIR}/m7_mast3r_slam.log`

**Wall-time:** ~10–20 min per site (SLAM 은 inference + BA 가 빠름).

> **주의:** upstream MASt3R-SLAM 의 정확한 entrypoint (`main.py` 위치 / CLI flag) 와 출력 파일명은 build 시점에 검수 필요 (`run_pipeline_p9.sh` line 114–115 NOTE; [adapters/README.md §1](adapters/README.md) 의 `TRAJECTORY_PATH` / `PLY_PATH` 보정 가이드).

### 3.3 Stage 2 — Adapter (MASt3R-SLAM → COLMAP-format)

`run_pipeline_p9.sh` line 135–167. GPU 불필요 (numpy 기반); m7 컨테이너 재활용.

**Docker call:**
```bash
docker run --rm \
    -v ${DATA_ROOT}:/data \
    -v ${REPO_ROOT}/experiments/adapters:/adapters \
    ars/m7_mast3r_slam:latest \
    python /adapters/mast3r_slam_to_colmap.py \
        --trajectory   /data/outputs/P9/${SITE}/${RUN}/pose_native/trajectory.txt \
        --intrinsics   /data/sites/${SITE}/calib/intrinsics.json \
        --frames-dir   /data/sites/${SITE}/runs/${RUN}/frames \
        --pointcloud   /data/outputs/P9/${SITE}/${RUN}/pose_native/points.ply \
        --output       /data/outputs/P9/${SITE}/${RUN}/pose/sparse/0 \
        --max-points 100000
```

**변환 내용:**
- Quaternion 순서: TUM `(qx,qy,qz,qw)` → COLMAP `(qw,qx,qy,qz)`
- Pose 방향: camera-to-world `T_wc` → world-to-camera `T_cw` (R 전치 + t 부호 반전)
- 파일 포맷: text 형식 `cameras.txt`, `images.txt`, `points3D.txt`

**산출물:**
- `${OUT_DIR}/pose/sparse/0/cameras.txt` — `1 OPENCV W H fx fy cx cy k1 k2 p1 p2`
- `${OUT_DIR}/pose/sparse/0/images.txt` — image_id + COLMAP-format pose + filename
- `${OUT_DIR}/pose/sparse/0/points3D.txt` — sparse seed points (PLY 가 없으면 trajectory bbox 기반 synthetic fallback)
- `${LOG_DIR}/adapter.log`

**Sanity check:** `cameras.txt` + `images.txt` 둘 다 없으면 `[FATAL] adapter 출력 누락` 으로 종료.

**Wall-time:** <1 min.

### 3.4 Stage 3 — M9 2DGS train (planar-prior representation) + native mesh

`run_pipeline_p9.sh` line 175–215. GPU `--gpu-rep` (default 1). 두 docker call (train + mesh extract).

**Docker call (train):**
```bash
docker run --rm --gpus "device=${GPU_REP}" \
    -v ${DATA_ROOT}:/data \
    ars/m9_2dgs:latest \
    python /opt/two_dgs/train.py \
        --source_path /data/outputs/P9/${SITE}/${RUN}/pose \
        --images      /data/sites/${SITE}/runs/${RUN}/frames \
        --model_path  /data/outputs/P9/${SITE}/${RUN}/recon \
        --iterations  30000 --resolution 1 --eval
```

**Docker call (native TSDF mesh extraction):**
```bash
docker run --rm --gpus "device=${GPU_REP}" \
    -v ${DATA_ROOT}:/data \
    ars/m9_2dgs:latest \
    python /opt/two_dgs/render.py \
        --model_path /data/outputs/P9/${SITE}/${RUN}/recon \
        --skip_train --skip_test \
        --mesh_res 1024
```

본 두 번째 호출이 2DGS 의 *native TSDF fusion* — 3DGS 대비 P9 의 핵심 강점. mesh 가 `recon/train/ours_30000/fuse_post.ply` 형태로 출력 (정확 경로는 [PAPER §3.7 Sub-stage 5a](../PAPER_DRAFT.md) 참조).

**산출물:**
- `${OUT_DIR}/recon/point_cloud/iteration_30000/point_cloud.ply` — 학습 완료 2DGS surface-aligned disks
- `${OUT_DIR}/recon/cameras.json` / `results.json` — PSNR/SSIM/LPIPS
- `${OUT_DIR}/recon/train/ours_30000/fuse_post.ply` — *native mesh* (BEV occupancy 변환 직접 입력)
- `${LOG_DIR}/m9_2dgs.log`

**Wall-time:** ~30–60 min train + ~5 min mesh extract.

### 3.5 Stage 4 — `compute_metrics.py` 집계

P1 과 동일 구조 + `--t-adapter` 추가 인자:

```bash
python3 compute_metrics.py \
    --pipeline P9 --site ${SITE} --run ${RUN} \
    --recon-dir ${OUT_DIR}/recon \
    --t-pose ${T_POSE} --t-adapter ${T_ADAPT} --t-rep ${T_REP} \
    --output ${OUT_DIR}/metrics.json
```

산출물 `metrics.json` 구조에 추가 필드 `wall_time_adapter_sec` 포함.

### 3.6 P9 전체 flow 요약

```
[frames/*.png] + [intrinsics.json] + [MASt3R checkpoint]
     │
     ▼
┌──────────────────────────────────────────┐
│  Stage 1: M7 MASt3R-SLAM (GPU 0)        │
│  dense matching prior + visual SLAM     │
└──────────────────────────────────────────┘
     │
     ▼  pose_native/{trajectory.txt, points.ply}
┌──────────────────────────────────────────┐
│  Stage 2: Adapter (no GPU)              │
│  mast3r_slam_to_colmap.py               │
│  TUM → COLMAP text + pose reversal      │
└──────────────────────────────────────────┘
     │
     ▼  pose/sparse/0/{cameras,images,points3D}.txt
┌──────────────────────────────────────────┐
│  Stage 3: M9 2DGS train (GPU 1)         │
│  train.py --iterations 30000            │
│  + render.py (native TSDF mesh)         │
└──────────────────────────────────────────┘
     │
     ▼  recon/point_cloud + recon/train/ours_30000/fuse_post.ply
┌──────────────────────────────────────────┐
│  Stage 4: compute_metrics.py (host)     │
│  PSNR/SSIM/LPIPS + wall-time (4 stages) │
└──────────────────────────────────────────┘
     │
     ▼
[metrics.json]
```

---

## 4. P2–P8 의 구현 상태 — 사전등록 가설만 (실험 deferred)

본 repository 의 현재 시점 (Tier 2) 에서 **P2–P8 은 실제 실험을 수행하지 않는다.** PAPER 본문 §3.3 Table 1b 에 *사전등록 가설* 로 enumerate 되어 있을 뿐, `run_pipeline_p{2..8}.sh` 와 그 의존 atomic methods (M2–M6) 의 Dockerfile / orchestration 은 **Tier 3 deferred**.

### 4.1 9 configurations 별 구현 상태

| Config | Pose | Rep | Dockerfile | run_pipeline_*.sh | 실제 실험 | PAPER 본문 |
|---|---|---|---|---|---|---|
| **P1** | M1 COLMAP | M8 3DGS | ✓ M1·M8 | ✓ | **✓ pilot 수행** | §3.3 / §4.3 / §5.1 H-Worst |
| P2 | M1 COLMAP | M9 2DGS | ✓ M1·M9 (M9 는 P9 와 공유) | ✗ | ✗ | §3.3 Tab. 1b row P2 (representation 격리 ablation 의 한 축) |
| P3 | M2 GLOMAP | M8 3DGS | ✗ M2 | ✗ | ✗ | §3.3 Tab. 1b row P3 (global SfM baseline) |
| P4 | M3 DUSt3R | M8 3DGS | ✗ M3 | ✗ | ✗ | §3.3 Tab. 1b row P4 (learning matching × volumetric) |
| P5 | M4 MASt3R | M9 2DGS | ✗ M4 | ✗ | ✗ | §3.3 Tab. 1b row P5 (learning matching × planar) |
| P6 | M5 DROID-SLAM | M8 3DGS | ✗ M5 | ✗ | ✗ | §3.3 Tab. 1b row P6 (deep SLAM × volumetric) |
| P7 | M6 DPV-SLAM | M9 2DGS | ✗ M6 | ✗ | ✗ | §3.3 Tab. 1b row P7 (low-mem deep SLAM × planar) |
| P8 | M7 MASt3R-SLAM | M8 3DGS | ✓ M7·M8 | ✗ | ✗ | §3.3 Tab. 1b row P8 (representation 격리 ablation 의 한 축) |
| **P9** | M7 MASt3R-SLAM | M9 2DGS | ✓ M7·M9 | ✓ | **✓ pilot 수행** | §3.3 / §4.3 / §5.1 H-Best |

**Atomic method 구현 상태:**

| Method | Dockerfile | 비고 |
|---|---|---|
| M1 COLMAP | ✓ `experiments/docker/m1_colmap/` | CUDA 11.8 + colmap 3.9.1 |
| M2 GLOMAP | ✗ | Tier 3 deferred |
| M3 DUSt3R | ✗ | Tier 3 deferred |
| M4 MASt3R | ✗ | Tier 3 deferred (M7 SLAM 의 backbone 이므로 별도 build) |
| M5 DROID-SLAM | ✗ | Tier 3 deferred |
| M6 DPV-SLAM | ✗ | Tier 3 deferred |
| M7 MASt3R-SLAM | ✓ `experiments/docker/m7_mast3r_slam/` | PyTorch 2.1+cu118 + MASt3R-SLAM upstream |
| M8 3DGS | ✓ `experiments/docker/m8_3dgs/` | + diff-gaussian-rasterization + simple-knn |
| M9 2DGS | ✓ `experiments/docker/m9_2dgs/` | + diff-surfel-rasterization |

### 4.2 즉시 추가 가능 — P2 & P8 (rep cross-ablation)

P2 와 P8 은 *atomic methods 가 이미 모두 구현* 되어 있으므로 (M1·M9, M7·M8) `run_pipeline_p2.sh` / `run_pipeline_p8.sh` 를 작성하는 것만으로 즉시 실행 가능. 구현 비용 작음 (~30 분 — 기존 P1·P9 스크립트의 docker call 조합).

**P2 = M1 COLMAP + M9 2DGS** (P1 ↔ P2 비교 = volumetric vs planar 격리 ablation; §5.3 "Why 2DGS > 3DGS" 의 *direct evidence*)

**P8 = M7 MASt3R-SLAM + M9 → M8 3DGS** (P8 ↔ P9 비교 = 동일 deep-prior pose 입력에서 representation 차이만 격리)

이 두 configuration 은 H-Gap / H-Mechanism 검정과 *independent* 한 새 가설 — *"동일 pose 에서 2DGS 가 3DGS 보다 우수"* — 의 직접 검증 evidence. 본 논문의 §5.3 mechanism argument 의 강도를 결정적으로 강화.

### 4.3 Tier 3 진입 시 추가 필요 — M2–M6 + P3–P7

M2 GLOMAP / M3 DUSt3R / M4 MASt3R / M5 DROID-SLAM / M6 DPV-SLAM 의 Dockerfile + adapter (각 method 의 native output → COLMAP-format) 작성이 필요. 예상 작업량:
- 각 method 당 Dockerfile + smoke test: ~1-2일
- 각 method → COLMAP adapter: ~0.5-1일 (M7 의 `mast3r_slam_to_colmap.py` template 재활용)
- 5 method × 평균 2일 = **~10 사람-일**

본 작업은 **Tier 3 deferred** — pilot 결과 (P1 vs P9) 에서 H-Gap / H-Mechanism 이 supported 로 검증되면 진입 가치 높음.

---

## 5. PAPER 본문에서 다루는 방식 + Tier 3 진입 조건

### 5.1 PAPER 본문의 "9 configurations" 표현 — 사전등록의 의미

PAPER §3.3 Table 1b 에서 **9 configurations 모두를 enumerate** 하며 H-Best (P9) · H-Worst (P1) 두 가설을 *사전등록* 한다. 본 사전등록은 cherry-picking / HARK (hypothesizing after results are known) 의 여지를 차단하는 핵심 commitment.

**중요:** 사전등록은 *어떤 configurations 를 실제 실행할지의 약속* 이지 *모든 configurations 의 실측 보고 의무* 가 아니다. 본 논문의 primary verdict 는:
- **H-Worst (P1) supported / refuted** — pilot 의 P1 결과 vs 다른 site/method ranking
- **H-Best (P9) supported / refuted** — pilot 의 P9 결과 vs P1 의 Δ
- **H-Gap (Δ_industrial > Δ_library)** — P1 ↔ P9 의 두 도메인별 Δ
- **H-Mechanism** — §4.5 ablation 의 P1 vs P9 sub-cluster 분리 검증

이 4 가설은 모두 **P1 + P9 의 6 site 결과만으로 검증 가능**. P2–P8 의 결과는 ranking 의 *완전한 분포* 를 보여주는 보강 evidence 이지 primary verdict 의 필수 조건이 아니다.

### 5.2 §4.3 Tab. 2 의 9-column matrix 의 운용

PAPER §4.3 Tab. 2 ("9 pipeline configurations × 2 domains × metrics") 는 모든 9 configurations 를 column 으로 두지만, 실제 fill 은 단계적:

| Tier | Fill 범위 | 시점 |
|---|---|---|
| Tier 2 (현재) | **P1 + P9 column 만** 실측 fill (나머지 7 column 은 `(TBD)` 또는 *not run* 표기) | Pilot 종료 후 |
| Tier 3 deferred | 추가 7 configuration fill (P2/P8 우선 → P3/P4/P5/P6/P7) | H-Gap supported 후 가치-driven 진입 |

본 단계적 fill 은 sub-paper 또는 follow-up 으로 확장 가능 — 본 논문이 *systems paper* 성격이므로 P1/P9 의 end-to-end 입증 + design principle C3 도출이 primary contribution.

### 5.3 Tier 3 진입 조건

Pilot (P1 + P9 × 6 site) 결과에서 다음이 관측되면 Tier 3 (M2–M6 + P2–P8) 진입 가치 높음:

| 신호 | Tier 3 진입 우선 순위 |
|---|---|
| H-Best (P9) + H-Worst (P1) 양쪽 모두 *supported* + Δ_industrial 가 시각적으로 크게 보임 | **P2 + P8 우선** (representation 격리 ablation → §5.3 mechanism 강화) — 비용 작음 |
| H-Mechanism cluster A.1/A.2/A.3 ablation 에서 강한 차이 관측 | **P3 + P5 추가** (learning matching 의 cluster A 우위 일반화 검증) |
| 모든 검정 supported + reviewer 가 "9-config full coverage" 요구 시 | **P4 / P6 / P7 추가** (deep SLAM 계열 internal comparison) |
| H-Gap / H-Best 중 하나라도 *refuted* | Tier 3 진입 보류 — primary verdict 의 mechanism 재해석 우선 |

### 5.4 본 단계의 명시 — Honest reporting

PAPER §5.5 Limitations 의 다음 항목으로 본 단계적 fill 을 명시화:

> **(L8) 9 configurations × 2 domains 의 부분 fill.** 본 논문의 primary verdict 는 P1 (H-Worst) 와 P9 (H-Best) 의 6 site 결과로 검증된다. 나머지 7 configurations (P2–P8) 는 사전등록 ranking enumeration 의 일부이나 본 single-paper scope 에서는 실측 미수행. 본 한계는 §4.3 Tab. 2 의 *not run* column 표기로 transparent 하게 명시되며, follow-up paper 또는 §6.2 F1 Tier 3 deferred work 으로 확장 commit.

> *주: L8 은 본 PIPELINE_FLOW.md 작성 시점에 기록되며, PAPER_DRAFT.md §5.5 의 후속 patch 로 등재 후보 (사용자 결정 대기).*

---

## 6. Cross-reference

- [PAPER_OUTLINE.md §3.3 Table 1b](../PAPER_OUTLINE.md) — 9 configurations enumeration
- [PAPER_DRAFT.md §1.4](../PAPER_DRAFT.md) — 4 사전등록 가설
- [PAPER_DRAFT.md §4.3 Tab. 2](../PAPER_DRAFT.md) — 9-column × 2-domain × metric matrix
- [PAPER_DRAFT.md §5.1 Tab. 4](../PAPER_DRAFT.md) — H-verdict 표
- [`scripts/run_pipeline_p1.sh`](scripts/run_pipeline_p1.sh) / [`scripts/run_pipeline_p9.sh`](scripts/run_pipeline_p9.sh) — 본 문서의 source code
- [`scripts/compute_metrics.py`](scripts/compute_metrics.py) — metrics.json schema
- [`adapters/mast3r_slam_to_colmap.py`](adapters/mast3r_slam_to_colmap.py) / [`adapters/colmap_to_intrinsics.py`](adapters/colmap_to_intrinsics.py) — P9 의 stage 2 adapter + P1→P9 intrinsics bridge
- [RUN_PILOT.md](RUN_PILOT.md) — 학교 서버 실행 가이드
