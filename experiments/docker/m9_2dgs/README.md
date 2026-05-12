# M9 — 2D Gaussian Splatting (planar-prior representation)

> Source: [hbb1/2d-gaussian-splatting](https://github.com/hbb1/2d-gaussian-splatting) — Huang et al. 2024, LR-[9]
> Role: **P9 (H-Best) representation stage** — surfel (planar disk) primitives, native mesh extraction
> Image tag: `ars/m9_2dgs:latest`

---

## 1. Build

```bash
cd experiments/docker/m9_2dgs
docker build -t ars/m9_2dgs:latest .
```

> Build time 15–25분. `diff-surfel-rasterization` 빌드가 무거움.

---

## 2. Smoke Test

```bash
docker run --rm --gpus all ars/m9_2dgs:latest \
    python -c "import torch, diff_surfel_rasterization, simple_knn; \
               print('torch', torch.__version__, \
                     'cuda', torch.cuda.is_available(), \
                     'surfel rasterizer OK')"
```

---

## 3. Input Contract — COLMAP-format sparse

2DGS는 3DGS와 동일한 COLMAP 포맷 `--source_path`를 요구한다. P9에서 M7 MASt3R-SLAM 출력은 Tier 2 adapter로 COLMAP-format 변환 후 입력.

```
data/outputs/P9/{site}/{run}/pose/
├── sparse/0/
│   ├── cameras.bin        ← M7 → COLMAP adapter 출력
│   ├── images.bin
│   └── points3D.bin
└── images/
```

> **Tier 1에서는 adapter 미구현**이므로, P9 end-to-end 실행은 Tier 2에서 가능. M9 단독 검증은 M1 COLMAP의 sparse 출력 (P2 cross-ablation 동작) 또는 NeRF Synthetic 등 public dataset로 가능.

---

## 4. Run (P9 representation stage 표준 호출)

```bash
SITE=I-1
RUN=run-01
PIPELINE=P9

# Train
docker run --rm --gpus '"device=1"' \
    -v "$(pwd)/data:/data" \
    ars/m9_2dgs:latest \
    python /opt/two_dgs/train.py \
        --source_path /data/outputs/${PIPELINE}/${SITE}/${RUN}/pose \
        --images /data/sites/${SITE}/runs/${RUN}/frames \
        --model_path /data/outputs/${PIPELINE}/${SITE}/${RUN}/recon \
        --iterations 30000 \
        --resolution 1 \
        --eval

# Render
docker run --rm --gpus '"device=1"' \
    -v "$(pwd)/data:/data" \
    ars/m9_2dgs:latest \
    python /opt/two_dgs/render.py \
        --model_path /data/outputs/${PIPELINE}/${SITE}/${RUN}/recon \
        --skip_train --skip_test

# Native mesh extraction (TSDF fusion from 2DGS surfels)
docker run --rm --gpus '"device=1"' \
    -v "$(pwd)/data:/data" \
    ars/m9_2dgs:latest \
    python /opt/two_dgs/render.py \
        --model_path /data/outputs/${PIPELINE}/${SITE}/${RUN}/recon \
        --skip_train --skip_test \
        --mesh_res 1024
```

---

## 5. I/O 규약

| 방향 | 경로 | 포맷 |
|---|---|---|
| 입력 | `/data/outputs/{P2\|P5\|P7\|P9}/{site}/{run}/pose/` | COLMAP-format sparse |
| 입력 | `/data/sites/{site}/runs/{run}/frames/` | 원본 PNG |
| 출력 | `/data/outputs/.../recon/point_cloud/iteration_30000/point_cloud.ply` | 2DGS surfel PLY |
| 출력 | `/data/outputs/.../recon/train/ours_30000/fuse_post.ply` | **TSDF fusion mesh** (native, BEV 입력 직결) |
| 출력 | `/data/outputs/.../recon/cameras.json` | train-view 메타 |

> **2DGS의 native mesh**는 SuGaR / Poisson 단계 불필요 → mesh extraction config A (2DGS native).
> 3DGS는 별도 SuGaR 단계 필요 (config B), sparse fallback은 Poisson (config C). [PAPER_OUTLINE §3.7](../../../PAPER_OUTLINE.md) 참조.

> **2DGS는 4개 pipeline (P2, P5, P7, P9)의 representation stage**로 재사용 (Table 1b).

---

## 6. GPU / Resource

| 항목 | Notes |
|---|---|
| VRAM | 12–18GB (3DGS와 유사 또는 약간 낮음 — surfel은 disk 1개 vs Gaussian 3D anisotropy) |
| 실행시간 | 30k iter 약 30–50분; mesh extraction 추가 5–10분 |
| 병렬성 | 단일 GPU per train. P9 representation은 host B의 GPU 1번 (README §6 of [experiments/README.md](../../README.md)) |

---

## 7. Hypothesis Tie-in

본 method는 H-Best 가설의 representation backbone. 평면이 지배적인 산업 site (벽/바닥/장비 면) 에서 surfel (planar prior)이 volumetric Gaussian (M8) 대비 mesh 품질·BEV-IoU·navigation success rate에서 우위가 사전등록된 기대 결과.

`H-Best = P9 = M7 (MASt3R-SLAM) × M9 (2DGS)`

---

## 8. Known Issues

| 증상 | 원인 | 대응 |
|---|---|---|
| `pip install ./submodules/diff-surfel-rasterization` build 시 `ModuleNotFoundError: No module named 'torch'` | PEP 517 build isolation이 setup.py에서 import torch를 격리시킴 | Dockerfile에 `pip install --no-build-isolation ./submodules/...` 사용 (현재 적용됨) |
| `diff_surfel_rasterization` import 실패 (runtime) | SM 8.9 미컴파일 또는 PyTorch 버전 불일치 | Dockerfile 재빌드, PyTorch 2.1.0 + cu118 고정 확인 |
| Mesh가 비어있음 (`fuse_post.ply` empty) | depth_truncation / voxel_size 부적절 | `--depth_trunc 3.0 --voxel_size 0.004` 등 산업 site 스케일 조정 |
| Open3D import 시 X11 오류 | headless 환경 OpenGL | 본 컨테이너는 mesh 저장만 — 시각화는 host에서 |
| Mast3R-SLAM pose → 2DGS bridge 부재 | Tier 2 adapter 미작성 | P9 end-to-end는 Tier 2에서 가능. M9 단독 검증은 P2 (M1 COLMAP pose) 경유. |

---

## 9. References

- LR-[9] B. Huang *et al.*, "2D Gaussian Splatting for Geometrically Accurate Radiance Fields," SIGGRAPH 2024.
- LR-[7] R. Murai *et al.*, "MASt3R-SLAM," CVPR 2025 (P9 pose stage).
