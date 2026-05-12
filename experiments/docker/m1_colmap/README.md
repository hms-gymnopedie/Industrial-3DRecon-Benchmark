# M1 — COLMAP (SfM pose stage)

> Source: [colmap/colmap](https://github.com/colmap/colmap) — Schönberger & Frahm 2016, LR-[1]
> Role: **P1 (H-Worst) pose stage** — hand-crafted SfM (SIFT + incremental BA)
> Image tag: `ars/m1_colmap:3.9.1`

---

## 1. Build

```bash
cd experiments/docker/m1_colmap
docker build -t ars/m1_colmap:3.9.1 .
```

> Build time 약 10–15분 (RTX 4090 host, network-bound).
> CUDA arch는 SM 8.9 (RTX 4090) 고정. 다른 GPU 사용 시 `--build-arg CMAKE_CUDA_ARCHITECTURES=...` 재정의.

---

## 2. Smoke Test

```bash
docker run --rm --gpus all ars/m1_colmap:3.9.1 colmap --help
# 출력에 'Commands' / 'feature_extractor' 등이 보이면 정상.
```

GPU SIFT extraction 검증:
```bash
docker run --rm --gpus all ars/m1_colmap:3.9.1 colmap feature_extractor --help \
    | grep -i "use_gpu"
# 'use_gpu' 옵션 표시되면 GPU build 정상.
```

---

## 3. Run (P1 pose stage 표준 호출)

입력: `/data/sites/{site}/runs/{run}/frames/*.png`
출력: `/data/outputs/P1/{site}/{run}/pose/sparse/0/` (COLMAP binary format)

### 3.1 Automatic reconstructor (권장 default)

```bash
SITE=I-1
RUN=run-01
PIPELINE=P1

docker run --rm --gpus '"device=0"' \
    -v "$(pwd)/data:/data" \
    ars/m1_colmap:3.9.1 \
    colmap automatic_reconstructor \
        --image_path  /data/sites/${SITE}/runs/${RUN}/frames \
        --workspace_path /data/outputs/${PIPELINE}/${SITE}/${RUN}/pose \
        --camera_model OPENCV \
        --single_camera 1 \
        --sparse 1 \
        --dense 0 \
        --use_gpu 1
```

> `--single_camera 1` — bodycam single device 가정 (intrinsics 단일).
> `--dense 0` — dense MVS 비활성 (3DGS는 sparse만 입력으로 사용).

### 3.2 Manual pipeline (fairness protocol 정밀제어용, Tier 2)

frame budget을 정확히 통제하려면 stage 분리:

```bash
# (a) feature extraction
colmap feature_extractor \
    --image_path /data/.../frames \
    --database_path /data/.../db.db \
    --ImageReader.camera_model OPENCV \
    --ImageReader.single_camera 1 \
    --SiftExtraction.use_gpu 1

# (b) feature matching
colmap exhaustive_matcher \
    --database_path /data/.../db.db \
    --SiftMatching.use_gpu 1

# (c) sparse reconstruction (incremental BA)
colmap mapper \
    --database_path /data/.../db.db \
    --image_path    /data/.../frames \
    --output_path   /data/.../pose/sparse
```

---

## 4. I/O 규약

| 방향 | 경로 | 포맷 |
|---|---|---|
| 입력 | `/data/sites/{site}/runs/{run}/frames/*.png` | PNG, lossless, sRGB 8-bit |
| 입력 (선택) | `/data/sites/{site}/calib/intrinsics.json` | OPENCV camera model |
| 출력 | `/data/outputs/P1/{site}/{run}/pose/sparse/0/cameras.bin` | COLMAP binary |
| 출력 | `/data/outputs/P1/{site}/{run}/pose/sparse/0/images.bin` | COLMAP binary |
| 출력 | `/data/outputs/P1/{site}/{run}/pose/sparse/0/points3D.bin` | COLMAP binary |

M8 3DGS는 `--source_path /data/outputs/P1/{site}/{run}/pose` (sparse/0 상위 디렉토리)를 입력으로 받는다.

---

## 5. GPU / Resource

| 항목 | Notes |
|---|---|
| VRAM | SIFT extraction ~2GB, BA 단계는 CPU/RAM bound |
| RAM | I-1 (5분, 9k frames) 기준 32GB 권장 |
| 실행시간 | 5분 영상 기준 약 30–60분 (frame budget에 비례) |
| 병렬성 | `--gpus '"device=0"'`로 단일 GPU 할당. SfM은 CPU thread 의존도 높음. |

---

## 6. Known Issues

| 증상 | 원인 | 대응 |
|---|---|---|
| `Could not find CUDA` build 실패 | base image의 CUDA path 누락 | `nvidia/cuda:11.8.0-devel-*` base 사용 확인 |
| SIFT GPU 동작 안 함 | docker run 시 `--gpus all` 누락 | 호출 옵션 점검 |
| Industrial site (textureless 벽) registration 실패 | hand-crafted SIFT 한계 (LR-[24] TAPA-MVS 동기) | **이는 H-Worst의 예측 동작이며 fail-as-finding으로 기록** |

---

## 7. References

- LR-[1] J. L. Schönberger and J.-M. Frahm, "Structure-from-Motion Revisited," CVPR 2016.
- 본 method가 industrial scene textureless area에서 어떻게 실패하는지의 hypothesis는 [PAPER_OUTLINE §3.5 Cluster A](../../../PAPER_OUTLINE.md) 참조.
