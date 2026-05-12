# M8 — 3D Gaussian Splatting (volumetric representation)

> Source: [graphdeco-inria/gaussian-splatting](https://github.com/graphdeco-inria/gaussian-splatting) — Kerbl et al. 2023, LR-[8]
> Role: **P1 (H-Worst) representation stage** — volumetric 3D Gaussian primitives
> Image tag: `ars/m8_3dgs:latest`

---

## 1. Build

```bash
cd experiments/docker/m8_3dgs
docker build -t ars/m8_3dgs:latest .
```

> Build time 15–20분 (CUDA extension 컴파일이 가장 무거움).
> SM 8.9 (RTX 4090) 고정. 다른 GPU 사용 시 `TORCH_CUDA_ARCH_LIST` 변경.

---

## 2. Smoke Test

```bash
docker run --rm --gpus all ars/m8_3dgs:latest \
    python -c "import torch, diff_gaussian_rasterization, simple_knn; \
               print('torch', torch.__version__, \
                     'cuda', torch.cuda.is_available(), \
                     'rasterizer OK')"

# 기대 출력: 'torch 2.1.0+cu118 cuda True rasterizer OK'
```

---

## 3. Input Contract — COLMAP sparse 디렉토리

3DGS는 COLMAP 포맷의 sparse reconstruction을 입력으로 받는다. M1 (P1 pose stage) 출력이 직접 호환:

```
data/outputs/P1/{site}/{run}/pose/
├── sparse/0/
│   ├── cameras.bin
│   ├── images.bin
│   └── points3D.bin
└── images/                ← 또는 별도 path. 원본 frame 디렉토리.
```

> 3DGS의 `--source_path`는 위 `pose/` 디렉토리 (sparse/0 상위).
> 원본 이미지는 `--images` 또는 default `images/` 서브디렉토리 참조.

---

## 4. Run (P1 representation stage 표준 호출)

```bash
SITE=I-1
RUN=run-01
PIPELINE=P1

# Train
docker run --rm --gpus '"device=1"' \
    -v "$(pwd)/data:/data" \
    ars/m8_3dgs:latest \
    python /opt/gaussian_splatting/train.py \
        --source_path /data/outputs/${PIPELINE}/${SITE}/${RUN}/pose \
        --images /data/sites/${SITE}/runs/${RUN}/frames \
        --model_path /data/outputs/${PIPELINE}/${SITE}/${RUN}/recon \
        --iterations 30000 \
        --resolution 1 \
        --eval

# Render (선택)
docker run --rm --gpus '"device=1"' \
    -v "$(pwd)/data:/data" \
    ars/m8_3dgs:latest \
    python /opt/gaussian_splatting/render.py \
        --model_path /data/outputs/${PIPELINE}/${SITE}/${RUN}/recon

# Metric (선택)
docker run --rm --gpus '"device=1"' \
    -v "$(pwd)/data:/data" \
    ars/m8_3dgs:latest \
    python /opt/gaussian_splatting/metrics.py \
        --model_path /data/outputs/${PIPELINE}/${SITE}/${RUN}/recon
```

---

## 5. I/O 규약

| 방향 | 경로 | 포맷 |
|---|---|---|
| 입력 | `/data/outputs/{P1\|P3\|P4\|P6\|P8}/{site}/{run}/pose/` | COLMAP sparse (binary) |
| 입력 | `/data/sites/{site}/runs/{run}/frames/` | 원본 PNG |
| 출력 | `/data/outputs/.../recon/point_cloud/iteration_30000/point_cloud.ply` | 3DGS native PLY |
| 출력 | `/data/outputs/.../recon/cameras.json` | train-view 메타 |
| 출력 | `/data/outputs/.../recon/cfg_args` | hyperparam log |

> **3DGS는 5개 pipeline (P1, P3, P4, P6, P8)의 representation stage**로 재사용 가능 (Table 1b).

---

## 6. GPU / Resource

| 항목 | Notes |
|---|---|
| VRAM | I-1 5분 영상 기준 14–20GB (Gaussian 개수에 비례, densification 이후 peak) |
| 실행시간 | 30k iter 약 30–50분 |
| 병렬성 | 단일 GPU per train. P1과 P9 (M9 2DGS) 별 GPU에서 병렬 가능 |
| 메모리 누수 주의 | 장시간 idle 시 host RAM에 PLY 누적 — 컨테이너 재시작으로 회수 |

---

## 7. Mesh Extraction (Tier 3 deferred)

본 Tier 1에서는 mesh extraction 미포함. Tier 3에서 SuGaR ([LR-17]) 컨테이너 추가:
- 3DGS → SuGaR mesh 변환
- BEV grid 변환 정확성 비교 (config A: 2DGS native / B: 3DGS-SuGaR / C: Poisson)

상세 spec은 [PAPER_OUTLINE §3.7](../../../PAPER_OUTLINE.md) 참조.

---

## 8. Known Issues

| 증상 | 원인 | 대응 |
|---|---|---|
| `pip install ./submodules/diff-gaussian-rasterization` build 시 `ModuleNotFoundError: No module named 'torch'` | PEP 517 build isolation이 setup.py에서 import torch를 격리시킴 | Dockerfile에 `pip install --no-build-isolation ./submodules/...` 사용 (현재 적용됨) |
| `diff_gaussian_rasterization` import 실패 (runtime) | SM 8.9 미컴파일 | Dockerfile의 `TORCH_CUDA_ARCH_LIST="8.9"` 확인 |
| `--source_path` Could not recognize scene type | sparse/0 누락 또는 단일 카메라 미설정 | M1 호출 시 `--single_camera 1` 확인 |
| Densification 후 OOM | 산업 site의 over-fragmented Gaussian | iteration 줄이거나 `--densify_grad_threshold` 상향 |
| Industrial reflective surface artifacts | hand-crafted SIFT pose error 누적 | **H-Worst 예측 동작 — fail-as-finding** |

---

## 9. References

- LR-[8] B. Kerbl *et al.*, "3D Gaussian Splatting for Real-Time Radiance Field Rendering," ACM ToG / SIGGRAPH 2023.
- LR-[1] J. L. Schönberger and J.-M. Frahm, "Structure-from-Motion Revisited" (COLMAP input source).
