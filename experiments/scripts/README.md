# Scripts

> 본 디렉토리는 ARS 실험 인프라의 **shell + Python 스크립트** 집합. 두 Tier로 구분:
>
> - **Tier 1** (verify): docker / GPU 환경 검증 + asset 다운로드 (이미 완료)
> - **Tier 2** (orchestration): 단일 site/run에 대한 P1 / P9 end-to-end 실행

---

## 1. Tier 1 — Environment Verification (이미 완료)

| 스크립트 | 역할 | 의존성 | 실행 위치 |
|---|---|---|---|
| [`verify_gpu.sh`](verify_gpu.sh) | NVIDIA driver / CUDA / docker GPU runtime 5단계 검증 | nvidia-smi, docker | host |
| [`download_weights.sh`](download_weights.sh) | MASt3R encoder checkpoint 다운로드 | curl/wget | host |
| [`verify_dockers.sh`](verify_dockers.sh) | M1/M7/M8/M9 image build + smoke test | docker | host |

### 1.1 표준 호출 순서

```bash
bash experiments/scripts/verify_gpu.sh                  # (a) 환경 확인
bash experiments/scripts/download_weights.sh            # (b) checkpoint 다운로드
bash experiments/scripts/verify_dockers.sh              # (c) 4 image build
```

### 1.2 Subset / skip-build 옵션

```bash
# 특정 image만 재빌드
bash experiments/scripts/verify_dockers.sh m8 m9

# 이미 빌드된 image의 smoke test만
bash experiments/scripts/verify_dockers.sh --skip-build
```

---

## 2. Tier 2 — Pipeline Orchestration

| 스크립트 | 역할 | 입력 | 출력 |
|---|---|---|---|
| [`run_pipeline_p1.sh`](run_pipeline_p1.sh) | **P1 (H-Worst)**: M1 COLMAP → M8 3DGS | site/run/iter/GPU | `data/outputs/P1/{site}/{run}/{pose,recon,logs,metrics.json}` |
| [`run_pipeline_p9.sh`](run_pipeline_p9.sh) | **P9 (H-Best)**: M7 MASt3R-SLAM → adapter → M9 2DGS | site/run/iter/GPU/weights | `data/outputs/P9/{site}/{run}/{pose_native,pose,recon,logs,metrics.json}` |
| [`run_pilot_i1.sh`](run_pilot_i1.sh) | I-1 site pilot driver — P1/P9 병렬 실행 + 비교 출력 | mode (single-host \| two-host) | 두 pipeline 결과 + compare table |
| [`compute_metrics.py`](compute_metrics.py) | recon 디렉토리 → metrics.json 변환 | recon-dir + wall times | metrics.json |

### 2.1 표준 호출 — single-host (4 GPU 단일 호스트)

```bash
# 4 GPU 모두 한 호스트에 있는 경우. P1과 P9가 GPU 0/1 vs 2/3로 병렬 분리.
bash experiments/scripts/run_pilot_i1.sh --single-host
```

### 2.2 표준 호출 — two-host (4090 × 2 서버 × 2 GPU)

```bash
# host A — P1만
bash experiments/scripts/run_pilot_i1.sh --only p1

# host B — P9만 (병렬)
bash experiments/scripts/run_pilot_i1.sh --only p9
```

### 2.3 단일 pipeline 직접 호출

```bash
bash experiments/scripts/run_pipeline_p1.sh \
     --site I-1 --run run-01 --iterations 30000 \
     --gpu-pose 0 --gpu-rep 1

bash experiments/scripts/run_pipeline_p9.sh \
     --site I-1 --run run-01 --iterations 30000 \
     --gpu-pose 0 --gpu-rep 1 \
     --weights "$(pwd)/experiments/weights"
```

### 2.4 Stage skip (재시작 / 부분 재실행)

각 pipeline 스크립트는 stage별 skip flag 제공:

```bash
# P1 pose만 재실행 (3DGS는 건너뜀 — train resume 기능과 별개)
bash run_pipeline_p1.sh --site I-1 --run run-01 --skip-rep

# P9 adapter + rep만 (M7 SLAM은 이미 끝났다고 가정)
bash run_pipeline_p9.sh --site I-1 --run run-01 --skip-pose
```

---

## 3. Argument Reference

### 3.1 공통 옵션 (P1 / P9)

| Flag | Default | Description |
|---|---|---|
| `--site`        | I-1   | site id (data/sites/{site}/ 매칭) |
| `--run`         | run-01 | run id (data/sites/{site}/runs/{run}/) |
| `--iterations`  | 30000 | 3DGS/2DGS train iter |
| `--data-root`   | `<repo>/data` | data 디렉토리 mount source |
| `--gpu-pose`    | 0     | pose stage container GPU index (host-local) |
| `--gpu-rep`     | 1     | representation stage container GPU index |

### 3.2 P9 추가 옵션

| Flag | Default | Description |
|---|---|---|
| `--weights`     | `<repo>/experiments/weights` | MASt3R checkpoint 디렉토리 |
| `--skip-adapt`  | off   | adapter stage skip |

### 3.3 pilot driver 옵션

| Flag | Default | Description |
|---|---|---|
| `--single-host` | off   | 한 호스트에서 P1+P9 병렬 (4 GPU 환경) |
| `--only`        | (empty) | `p1` 또는 `p9`만 실행 (two-host topology) |

---

## 4. Output Layout (per pipeline run)

```
data/outputs/{P1|P9}/{site}/{run}/
├── pose_native/        ← P9 only — MASt3R-SLAM native output
├── pose/
│   └── sparse/0/       ← COLMAP-format (P1: binary, P9: text via adapter)
├── recon/
│   ├── point_cloud/iteration_30000/point_cloud.ply
│   ├── cameras.json
│   ├── cfg_args
│   ├── results.json    ← 3DGS/2DGS metrics 출력 (PSNR/SSIM/LPIPS)
│   └── train/ours_30000/fuse_post.ply  ← P9 (2DGS) native mesh
├── logs/
│   ├── m1_colmap.log   ← P1
│   ├── m7_mast3r_slam.log  ← P9
│   ├── adapter.log     ← P9
│   ├── m8_3dgs.log     ← P1
│   └── m9_2dgs.log     ← P9
└── metrics.json        ← compute_metrics.py 산출물
```

자세한 layout 규약은 [`data/README.md`](../data/README.md) 참조.

---

## 5. Frame Budget / Fairness (현재 미적용)

[PAPER_OUTLINE §3.6](../../PAPER_OUTLINE.md) 의 fairness protocol (sharpness threshold + FPS matching) 은 **본 Tier 2에서 미적용**. M1과 M7 모두 native frame set 전체를 사용. Frame budget 정규화는 Tier 3에서 별도 preprocessing stage로 추가 예정.

> Pilot 단계에서는 H-Best vs H-Worst 의 raw signal 확인이 우선. Fairness 미보정 상태에서 P9 ≫ P1 이면 oracle-level 차이로 해석 가능 (sensitivity는 Tier 3에서 분리).

---

## 6. Metrics Coverage

본 Tier 2의 `metrics.json` 에는 다음만 포함:

| 항목 | 측정 가능 |
|---|---|
| Wall time per stage / total | ✅ |
| n_gaussians (recon ply vertex 수) | ✅ |
| PSNR / SSIM / LPIPS (3DGS/2DGS eval split) | ✅ |
| n_views registered | ✅ |
| **VRAM peak** | ❌ (별도 nvidia-smi monitor 필요) |
| **Chamfer distance** | ❌ (GT mesh 없음 — 산업 site) |
| **BEV-IoU** | ❌ (BEV grid 변환 Tier 3) |
| **RRT* success rate** | ❌ (IsaacSim Tier 3) |

Tier 3 navigation track 진입 시 BEV/RRT* metrics 추가.

---

## 7. Troubleshooting

| 증상 | 가능 원인 | 점검 항목 |
|---|---|---|
| `[FATAL] frames 디렉토리 없음` | data layout 미준수 | `data/sites/{site}/runs/{run}/frames/*.png` 존재 확인 |
| `[FATAL] sparse reconstruction 출력 누락` (P1) | COLMAP registration 실패 | textureless area? `--ImageReader.single_camera 1` 옵션? (자동 호출에선 default OK) |
| `[FATAL] adapter 출력 누락` (P9) | MASt3R-SLAM native output 파일명 불일치 | `pose_native/` 내 실제 파일명 확인 → `run_pipeline_p9.sh` 의 `TRAJECTORY_PATH` 보정 |
| `[FATAL] intrinsics JSON 없음` (P9) | calibration 미실시 | `data/sites/{site}/calib/intrinsics.json` 작성 ([data/README.md §4](../data/README.md)) |
| metrics.json status=incomplete | recon stage 도달 못 함 또는 results.json 미생성 | `logs/m8_3dgs.log` 또는 `logs/m9_2dgs.log` 확인 |
| 두 컨테이너 동시 실행 시 GPU OOM | 같은 GPU 중복 할당 | `--gpu-pose` / `--gpu-rep` 충돌 확인 |
| Docker `--gpus '"device=N"'` 인용 오류 | shell escaping | bash 5.x 이상 권장, `set -euo pipefail` 환경 |

---

## 8. Cross-reference

- 전체 실험 plan: [`experiments/README.md`](../README.md)
- Adapter 사양: [`experiments/adapters/README.md`](../adapters/README.md)
- 데이터 layout: [`experiments/data/README.md`](../data/README.md)
- 가설 / pipeline 매핑: [PAPER_OUTLINE §3.3 Table 1b](../../PAPER_OUTLINE.md)
- Fairness protocol: [PAPER_OUTLINE §3.6](../../PAPER_OUTLINE.md)
