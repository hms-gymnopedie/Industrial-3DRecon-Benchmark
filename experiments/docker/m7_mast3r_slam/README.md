# M7 — MASt3R-SLAM (Deep-prior visual SLAM)

> Source: [rmurai0610/MASt3R-SLAM](https://github.com/rmurai0610/MASt3R-SLAM) — Murai et al. 2025, LR-[7]
> Role: **P9 (H-Best) pose stage** — MASt3R-encoder 기반 deep-prior dense visual SLAM
> Image tag: `ars/m7_mast3r_slam:latest`
> Upstream MASt3R / Croco: [naver/mast3r](https://github.com/naver/mast3r), [naver/croco](https://github.com/naver/croco)

---

## 1. Build

```bash
cd experiments/docker/m7_mast3r_slam
docker build -t ars/m7_mast3r_slam:latest .
```

> Build time 20–30분 (CUDA toolchain + PyTorch + lietorch 컴파일).
> 일부 환경에서 `lietorch` 빌드가 host glibc/CUDA arch에 민감 — `TORCH_CUDA_ARCH_LIST="8.9"` 환경변수 (Dockerfile에 고정) 변경 금지.

---

## 2. Smoke Test

```bash
# (a) PyTorch GPU 정상 인식 확인
docker run --rm --gpus all ars/m7_mast3r_slam:latest \
    python -c "import torch; print(torch.__version__, torch.cuda.is_available(), torch.cuda.get_device_name(0))"

# 기대: '2.1.0+cu118 True NVIDIA GeForce RTX 4090'

# (b) MASt3R-SLAM 모듈 import 확인
docker run --rm --gpus all ars/m7_mast3r_slam:latest \
    python -c "import sys; sys.path.insert(0, '/opt/mast3r_slam'); import mast3r_slam; print('MASt3R-SLAM module OK')"

# (실제 모듈 이름은 repo 구조에 따라 조정 — 'mast3r_slam' / 'mast3r' / 'src' 등 변종 가능)
```

---

## 3. Weight Preparation

MASt3R encoder checkpoint는 컨테이너 외부에 보관 후 `-v /host/weights:/weights` mount.

```bash
# Host에서 1회 실행
bash experiments/scripts/download_weights.sh
# → ./weights/MASt3R_ViTLarge_BaseDecoder_512_catmlpdpt_metric.pth 생성
```

컨테이너 내부에서는 환경변수 `$MAST3R_CHECKPOINT` (default: `/weights/MASt3R_ViTLarge_BaseDecoder_512_catmlpdpt_metric.pth`)로 참조.

---

## 4. Run (P9 pose stage 표준 호출)

> 정확한 CLI는 upstream repo의 `main.py` / `run.py` 인터페이스에 따른다.
> 아래는 frame-folder 입력 / pose+sparse output을 가정한 **표준 wrapper**.

```bash
SITE=I-1
RUN=run-01
PIPELINE=P9

docker run --rm --gpus '"device=0"' \
    -v "$(pwd)/data:/data" \
    -v "$(pwd)/weights:/weights" \
    ars/m7_mast3r_slam:latest \
    python /opt/mast3r_slam/main.py \
        --image_dir /data/sites/${SITE}/runs/${RUN}/frames \
        --output_dir /data/outputs/${PIPELINE}/${SITE}/${RUN}/pose_native \
        --checkpoint $MAST3R_CHECKPOINT \
        --intrinsics /data/sites/${SITE}/calib/intrinsics.json \
        --device cuda:0
```

> `pose_native` 디렉토리에 MASt3R-SLAM의 native 포맷 (trajectory + sparse points) 저장.
> 이후 Tier 2 adapter가 `pose/sparse/0/{cameras,images,points3D}.bin` (COLMAP 포맷)으로 직렬화 → M9 2DGS 입력.

---

## 5. I/O 규약

| 방향 | 경로 | 포맷 |
|---|---|---|
| 입력 | `/data/sites/{site}/runs/{run}/frames/*.png` | PNG sRGB |
| 입력 | `/data/sites/{site}/calib/intrinsics.json` | OPENCV camera model |
| 입력 | `/weights/MASt3R_ViTLarge_*.pth` | PyTorch checkpoint |
| 출력 (native) | `/data/outputs/P9/{site}/{run}/pose_native/` | trajectory.txt + sparse depth/points |
| 출력 (Tier 2) | `/data/outputs/P9/{site}/{run}/pose/sparse/0/` | COLMAP binary (adapter 변환) |

**MASt3R-SLAM → COLMAP-format adapter**는 본 Tier 1 범위 밖. M9 2DGS는 P9에서 이 adapter 출력을 입력으로 받음.

---

## 6. GPU / Resource

| 항목 | Notes |
|---|---|
| VRAM | 약 14–18GB (ViT-Large encoder + dense SLAM state). 24GB 4090에 여유 있음. |
| 실행시간 | 5분 영상 약 15–25분 (frame budget · keyframe density에 비례) |
| 병렬성 | 단일 GPU per run. P9 pose stage는 한 host의 GPU 0번에 고정 (README §6 of [experiments/README.md](../../README.md)) |

---

## 7. Known Issues

| 증상 | 원인 | 대응 |
|---|---|---|
| `lietorch` 빌드 실패 | host CUDA arch ≠ container arch | `TORCH_CUDA_ARCH_LIST="8.9"` 강제 (RTX 4090만 지원) |
| OOM during SLAM tracking | high-resolution frames + dense pyramid | 입력 1080p 유지 시 4090 24GB 가능; 1440p 이상은 downscale 필요 |
| Checkpoint 404 | Naver Labs CDN URL 변경 가능성 | `download_weights.sh` 안 URL 갱신 후 재시도 |
| Industrial dynamic agents (작업자) | foreground motion → SLAM corruption | Tier 3 SAM2/YOLO masking 적용 (LR-[13][14]) |

---

## 8. References

- LR-[7] R. Murai *et al.*, "MASt3R-SLAM: Real-Time Dense SLAM with 3D Reconstruction Priors," CVPR 2025.
- LR-[4] V. Leroy *et al.*, "Grounding Image Matching in 3D with MASt3R," ECCV 2024 (encoder origin).
- LR-[3] S. Wang *et al.*, "DUSt3R," CVPR 2024 (Croco lineage).

## 9. Hypothesis Tie-in

본 method는 H-Best 가설의 pose backbone. 산업 도메인의 textureless / 동적 agent / 저조도 (Cluster A/B/C, [PAPER_OUTLINE §3.5](../../../PAPER_OUTLINE.md))에서 hand-crafted SIFT (M1) 대비 ATE 우위가 사전등록된 기대 결과.
