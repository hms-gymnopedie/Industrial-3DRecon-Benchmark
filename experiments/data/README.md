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
    │   ├── frames/              ← sharp RGB PNG (학습 입력)
    │   │   ├── 0001.png
    │   │   ├── 0002.png
    │   │   └── ...
    │   ├── masks/               ← dynamic instance mask PNG (선택)
    │   │   ├── 0001.png         ← frames/0001.png 과 1:1 대응
    │   │   ├── 0002.png
    │   │   └── ...
    │   └── frames_meta.json     ← timestamp, capture FPS
    ├── run-02/
    └── run-03/
```

각 site에 대해 **최소 3 capture run** 권장 (RRT* navigation runs와 별개; 본 절은 영상 capture run).

**`frames/` vs `masks/` 관계:**
- `frames/` 가 *primary input*. P1 / P9 모두 이 폴더의 PNG 를 학습 입력으로 사용.
- `masks/` 는 PAPER §3.2 (d) 의 binary exclusion mask 산출물 (SAM 2.1 / SAM 3 계). 사용자 video-to-image preprocessing 모듈이 frame 추출과 동시에 생성한 mask 를 본 폴더에 배치.
- **두 폴더는 *독립 collection* — 부분집합 / 카운트 관계 강제 없음.** 두 종류 비대칭이 정상 상태로 발생: (i) `skip_empty` 정책 — dynamic instance 검출 0건 frame 의 mask 미생성 → `len(masks) < len(frames)` 가능. (ii) `manual sharp reclassification` — 사용자가 sharp 의 불필요 frame 을 사후 삭제한 경우 그에 대응하는 mask 가 *orphan* 으로 남을 수 있음 → `masks` 에 `frames` 에 없는 파일명 존재 가능.
- §4.5e cluster B.1 ablation 은 두 폴더의 *intersection* (sharp ∩ mask, 파일명 동일) 만 evidence 집합으로 사용 — 부분집합 가정 깨져도 자동 정합 (orphan mask 는 학습 입력 부재로 자동 제외).
- `masks/` intersection 이 0개라면 ablation 자체가 trivial (mask on ≡ mask off) — 해당 site 는 §4.5e 결과 row 에서 N/A 처리.
- 파일명 매칭 규약: mask 파일이 sharp 파일과 *짝* 을 이룰 때만 정확히 `frames/000001.png` ↔ `masks/000001.png` (확장자 포함 동일 파일명; binary mask 도 PNG 로 저장).

**`frames/` 생성 경로 — 사용자 video-to-image 모듈 (사전 통합):**

본 ARS pilot 의 사용자 측 video-to-image 전처리 모듈은 PAPER §3.2 의 4 sub-stage 를 사전 통합한 단일 도구이다:

1. **비디오 불러오기** — input raw bodycam video
2. **Frame 나누기** — FPS-based 균일 downsample (default 5 fps) [§3.2(a)]
3. **Blur 자동삭제** — Laplacian variance threshold [§3.2(b)]
4. **유사도 기준 중복제거** — visually redundant frame 제거 [§3.2(c)]
5. **Masking 처리** — SAM2 / YOLOv8-seg instance mask 자동 생성 [§3.2(d)]

따라서 `frames/` 의 PNG 수 N 은 raw video frame 수가 아닌 *4 sub-stage 통과 후 effective frame 수*. §3.6 F4 의 frame budget 1,500 은 본 effective N 에 대한 정의이며, run_pipeline_*.sh 가 sub-sample / dense resample 로 정규화한다.

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

- **파일명:** zero-pad numeric PNG (권장 6자리 `000001.png` ~ `999999.png`, 동일 site/run 내 *동일 자릿수* 필수). 시간 순서로 lexicographic sort 가 가능해야 한다. `1.png, 2.png, ..., 10.png` 같은 no-padding 명명은 sort 가 `1, 10, 2, ...` 로 깨지므로 금지.
- **확장자:** 소문자 `.png` 만 인식 (`mast3r_slam_to_colmap.py::list_frames()` 가 `.suffix.lower() == ".png"` 매칭). `.PNG` / `.jpg` / `.jpeg` 는 자동 skip.
- **색공간:** sRGB 8-bit (필요 시 raw 에서 변환).
- **압축:** PNG lossless (JPEG 사용 금지 — repeatable artifact 방지 + novel-view PSNR/SSIM noise floor 고정).
- **해상도:** capture 원본 유지 (downscale 은 pipeline 내부 책임).
- **Frame index = capture timestamp 순서 (오름차순).** 사용자 video-to-image 모듈의 dedup (§3.2 (c) dHash) 으로 인해 index 가 sparse 해도 (예: 0001, 0003, 0007, ...) lexicographic sort 가 temporal order 와 일치하면 OK.
- **sharp ↔ mask 짝 (pair) 매칭 — 부분집합 강제 없음:** mask 파일이 sharp 와 짝을 이룰 때만 정확히 `masks/000001.png` 파일명이 `frames/000001.png` 와 동일. 두 폴더는 *독립 collection* 이며 부분집합 / 카운트 관계는 강제하지 않는다 (PAPER §3.2 (d) — skip_empty 정책 + manual sharp reclassification 두 비대칭 정상). §4.5e cluster B.1 ablation 의 *full-set comparison* 은 intersection I = frames ∩ masks 만 evidence 로 사용 — I 밖 frame (sharp-only 또는 orphan mask) 은 mask on/off 두 condition 모두에서 자동 정합 (sharp-only 는 그대로 학습 포함, orphan mask 는 학습 입력 부재로 자동 무시).

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
