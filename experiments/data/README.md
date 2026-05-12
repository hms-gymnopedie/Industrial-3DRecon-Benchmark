# Data Layout

> Site / run / frame 디렉토리 규약 ([PAPER_OUTLINE.md](../../PAPER_OUTLINE.md) §4.1 기준)

---

## 1. 상위 구조

```
data/
├── sites/
│   ├── I-1/   ← Industrial site 1
│   ├── I-2/   ← Industrial site 2
│   ├── I-3/   ← Industrial site 3
│   ├── L-1/   ← Library control site 1
│   ├── L-2/   ← Library control site 2
│   └── L-3/   ← Library control site 3
└── outputs/
    └── {pipeline_id}/{site_id}/{run_id}/
        ├── pose/
        ├── recon/
        └── metrics.json
```

> 본 디렉토리는 docker container의 `/data` mount point에 매핑된다 (`docker run -v $(pwd)/data:/data ...`).

---

## 2. Site 디렉토리 규약

```
sites/I-1/
├── meta.yaml                ← 메타데이터 (capture 정보)
├── calib/
│   └── intrinsics.json      ← bodycam fx, fy, cx, cy, distortion
└── runs/
    ├── run-01/
    │   ├── frames/
    │   │   ├── 000000.png
    │   │   ├── 000001.png
    │   │   └── ...
    │   └── frames_meta.json ← timestamp, capture FPS
    ├── run-02/
    └── run-03/
```

각 site에 대해 **최소 3 capture run** 권장 (RRT* navigation runs와 별개; 본 절은 영상 capture run).

---

## 3. `meta.yaml` schema

```yaml
site_id: I-1
type: industrial            # industrial | library_control
description: "산업현장 — 작업장 A동 1층 (textureless 벽 + 작업자 dynamic)"
mechanism_clusters:         # PAPER_OUTLINE §3.5
  - A1_textureless          # Visual Ambiguity
  - A2_reflective
  - B1_dynamic              # Scene Non-staticity
  - C1_low_light            # Photometric Drift
capture:
  device: "GoPro Hero 11 Black (bodycam mount)"
  resolution: [1920, 1080]
  fps: 30
  duration_target_sec: 300  # 5분
  total_runs: 3
notes: |
  Site 접근일 / 기상 / 조명 조건 등 비정형 메타.
```

---

## 4. `intrinsics.json` schema

```json
{
  "model": "OPENCV",
  "width": 1920,
  "height": 1080,
  "fx": 1430.5,
  "fy": 1431.2,
  "cx": 960.1,
  "cy": 540.3,
  "k1": -0.012,
  "k2": 0.003,
  "p1": 0.0,
  "p2": 0.0,
  "calibration_source": "checkerboard 9x6, OpenCV calibrateCamera, RMS=0.31px"
}
```

> COLMAP `cameras.txt` `OPENCV` model과 직결.

---

## 5. `frames/` 규약

- 파일명: 6자리 zero-pad PNG (`000000.png` ~ `0NNNNN.png`)
- 색공간: sRGB 8-bit (필요 시 raw에서 변환)
- 압축: PNG lossless (jpeg 사용 금지 — repeatable artifact 방지)
- 해상도: capture 원본 유지 (downscale은 pipeline 내부 책임)
- frame index = capture timestamp 순서 (오름차순)

---

## 6. `frames_meta.json` schema

```json
{
  "fps_capture": 30.0,
  "duration_sec": 302.4,
  "n_frames": 9072,
  "timestamps_ms": [0, 33, 67, ...]
}
```

> Pipeline 내부 sampling/sharpness filtering 후의 frame budget은 별도 manifest로 기록 (Tier 2).

---

## 7. `outputs/{pipeline_id}/...` 규약

Tier 2 orchestration에서 채워질 출력 layout — 본 commit에서는 schema만 예약.

```
outputs/P1/I-1/run-01/
├── pose/
│   └── sparse/0/            ← COLMAP-format (cameras.bin, images.bin, points3D.bin)
├── recon/
│   ├── point_cloud.ply      ← 3DGS/2DGS native ply
│   └── checkpoint/          ← train state
└── metrics.json             ← PSNR/SSIM/LPIPS/Chamfer/mem/time
```

`pipeline_id ∈ {P1, P2, ..., P9}`. M7 MASt3R-SLAM pose 출력은 어댑터 (Tier 2)를 통해 COLMAP-format으로 직렬화되어 `pose/sparse/0/`에 동일하게 배치.

---

## 8. .gitignore 권장

```
data/sites/*/runs/*/frames/
data/outputs/
```

원본 영상 / 중간산출물은 git tracking 대상 아님. 메타데이터 (`meta.yaml`, `intrinsics.json`, `frames_meta.json`)만 tracking.

---

## 9. Cross-reference

- 데이터 수집 plan: [PAPER_OUTLINE §4.1](../../PAPER_OUTLINE.md)
- Fairness protocol (frame budget): [PAPER_OUTLINE §3.6](../../PAPER_OUTLINE.md)
- Mechanism cluster mapping: [PAPER_OUTLINE §3.5](../../PAPER_OUTLINE.md)
