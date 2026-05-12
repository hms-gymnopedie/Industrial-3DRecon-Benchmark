# Experiments — 9 Atomic Methods × 9 Pipeline Configurations

> ARS `experiment-setup` Tier 1 deliverable
> 생성일: 2026-05-12
> Target: 산업현장 보디캠 영상 기반 3D 재구성 파이프라인 비교평가 ([PAPER_OUTLINE.md](../PAPER_OUTLINE.md) §3, §4)

---

## 1. Scope (이 디렉토리)

본 디렉토리는 논문의 **실험 인프라**를 담는다. 현재 Tier 1 (Pilot-first) 범위로 사전등록 가설 검증에 필요한 최소 method 4개와 pipeline 2개를 우선 dockerize.

| Tier | 구성요소 | 본 commit 포함 |
|---|---|---|
| **Tier 1** | M1, M7, M8, M9 dockerfiles + P1 / P9 입출력 규약 | ✅ |
| Tier 2 | M2, M3, M4, M5, M6 dockerfiles + P2~P8 orchestration | ⏳ deferred |
| Tier 3 | Preprocessing (SAM2/YOLO) + Mesh (SuGaR/Poisson) + BEV + IsaacSim + Stat | ⏳ deferred |

**사전등록 (pre-registered):**
- H-Best = **P9** = M7 MASt3R-SLAM + M9 2DGS
- H-Worst = **P1** = M1 COLMAP + M8 3DGS

---

## 2. Hardware Assumption

| 항목 | Spec |
|---|---|
| GPU | NVIDIA RTX 4090 (Ada Lovelace, SM 8.9), 24GB VRAM |
| Host count | 2 server × 2 GPU = 4 GPU total |
| CUDA driver | ≥ 535.x (CUDA 12.2 runtime, 11.8 backwards compat) |
| Docker | NVIDIA Container Toolkit 설치 필수 (`docker run --gpus all` 검증) |
| Disk | per-pipeline ~50GB (raw frames + intermediate + final recon) |

> Driver/runtime는 `scripts/verify_gpu.sh`로 일괄 검증.

---

## 3. Directory Layout

```
experiments/
├── README.md                          ← 본 파일
├── data/
│   └── README.md                      ← site/run/frame 디렉토리 규약
├── docker/
│   ├── m1_colmap/                     ← M1 COLMAP 3.9.1
│   │   ├── Dockerfile
│   │   └── README.md
│   ├── m7_mast3r_slam/                ← M7 MASt3R-SLAM
│   │   ├── Dockerfile
│   │   └── README.md
│   ├── m8_3dgs/                       ← M8 3DGS (graphdeco-inria)
│   │   ├── Dockerfile
│   │   └── README.md
│   └── m9_2dgs/                       ← M9 2DGS (hbb1)
│       ├── Dockerfile
│       └── README.md
└── scripts/
    ├── verify_gpu.sh                  ← driver + nvidia-smi + docker GPU runtime 검증
    ├── verify_dockers.sh              ← 4 image build + smoke test
    └── download_weights.sh            ← MASt3R-SLAM/MASt3R checkpoint 다운로드
```

---

## 4. Setup Workflow (Tier 1)

순서 준수 권장. 각 단계는 next step의 전제조건.

```
[1] verify_gpu.sh
       ↓ (nvidia-smi/CUDA/docker GPU 정상)
[2] download_weights.sh
       ↓ (MASt3R encoder checkpoint /weights/ 배치 완료)
[3] verify_dockers.sh
       ↓ (M1, M7, M8, M9 image build + smoke test pass)
[4] (Tier 2 deferred) P1 / P9 end-to-end orchestration script 작성
       ↓
[5] (Tier 2 deferred) I-1 site pilot run 실행 → metrics 비교
```

---

## 5. Pipeline Pairing (P1 / P9)

| Pipeline | Pose stage | Representation stage | Pose → Rep 인터페이스 |
|---|---|---|---|
| **P1** (H-Worst) | M1 COLMAP | M8 3DGS | COLMAP `sparse/0/` (cameras/images/points3D.bin) → 3DGS `--source_path` |
| **P9** (H-Best) | M7 MASt3R-SLAM | M9 2DGS | MASt3R-SLAM `output/` (poses + sparse depth) → COLMAP 포맷 변환 어댑터 (Tier 2 작성 예정) → 2DGS `--source_path` |

> M7 → M9 어댑터는 Tier 2에서 작성 (MASt3R-SLAM의 native output을 COLMAP-style `cameras.txt`/`images.txt`/`points3D.txt`로 직렬화).

---

## 6. GPU Allocation (4 GPU, P1 + P9 병렬)

권장 배분 (NVIDIA_VISIBLE_DEVICES 기준):

| GPU id | Stage | 컨테이너 |
|---|---|---|
| 0 (서버 A) | P1 pose (COLMAP SfM) | m1_colmap |
| 1 (서버 A) | P1 rep (3DGS train) | m8_3dgs |
| 0 (서버 B) | P9 pose (MASt3R-SLAM) | m7_mast3r_slam |
| 1 (서버 B) | P9 rep (2DGS train) | m9_2dgs |

> P1/P9 fully parallel. Tier 2의 P2~P8 추가 시 동일 배분 응용.

---

## 7. Fairness Protocol Hooks (Tier 2 예정)

§3.6 frame budget 정규화는 본 Tier 1에서는 미구현. Tier 2에서:
- Sharpness threshold (Pertuz13 LR-[15]) 통과 frame만 sample
- FPS-equivalent budget (capture FPS × duration → 모든 method 동일 frame 수)
- M7 MASt3R-SLAM keyframe 수 = M1 COLMAP image registration 수 (matched budget)

---

## 8. Per-Method Detail

각 method 세부 사항 (build args, run command, I/O 규약)은 해당 디렉토리 README 참조:

- [M1 COLMAP](docker/m1_colmap/README.md)
- [M7 MASt3R-SLAM](docker/m7_mast3r_slam/README.md)
- [M8 3DGS](docker/m8_3dgs/README.md)
- [M9 2DGS](docker/m9_2dgs/README.md)
- [Data layout](data/README.md)

---

## 9. Deferred (Tier 2 / Tier 3)

본 commit에서 의도적으로 제외:
- M2 GLOMAP, M3 DUSt3R, M4 MASt3R, M5 DROID-SLAM, M6 DPV-SLAM (5 dockerfile)
- P2~P8 end-to-end orchestration script
- M7 → COLMAP-format adapter (P9 pose stage → rep stage bridge)
- SAM2 (LR-[13]) + YOLOv8 (LR-[14]) preprocessing pipeline
- SuGaR (LR-[17]) / Poisson (LR-[16]) mesh extraction
- BEV occupancy grid construction
- IsaacSim + Spot RRT* navigation (1,080 runs)
- Moving-block bootstrap (LR-[26]) statistical analysis pipeline

---

## 10. References (LR-shorthand)

- M1: Schönberger16 ([LR-1]) COLMAP
- M7: Murai25 ([LR-7]) MASt3R-SLAM
- M8: Kerbl23 ([LR-8]) 3DGS
- M9: Huang24 ([LR-9]) 2DGS
