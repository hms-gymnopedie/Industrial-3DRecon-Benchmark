# Adapters

> Pipeline stage 간 데이터 포맷 변환 어댑터.
> 본 디렉토리는 docker container 외부 (host) 또는 기존 method container 내부에서 실행되는 경량 변환 스크립트를 보관한다.

---

## 1. `mast3r_slam_to_colmap.py` — P9 Stage 1→2 Bridge

P9 (H-Best) pipeline에서 M7 MASt3R-SLAM의 native output을 M9 2DGS의 입력 (COLMAP-format sparse) 으로 변환.

### 1.1 입력

| 항목 | 경로 (default) | 포맷 | 비고 |
|---|---|---|---|
| Trajectory | `pose_native/trajectory.txt` | **TUM**: `ts tx ty tz qx qy qz qw` (per line) | timestamp 정렬 가정. # 주석 허용. |
| Intrinsics | `sites/{site}/calib/intrinsics.json` | OPENCV camera model JSON (data/README.md §4) | single camera 가정. |
| Frames | `sites/{site}/runs/{run}/frames/*.png` | sorted PNG | image_id ↔ filename 1:1 매칭. |
| Pointcloud (선택) | `pose_native/points.ply` | PLY (vertex.x/y/z, 선택적 RGB) | 없으면 trajectory bbox 기반 synthetic scatter. |

> **MASt3R-SLAM의 native 출력 파일명은 upstream repo 버전에 따라 다를 수 있다.** 실제 실행 후 `pose_native/` 의 산출물을 확인하고 [run_pipeline_p9.sh](../scripts/run_pipeline_p9.sh)의 `TRAJECTORY_PATH` / `PLY_PATH` 변수를 보정할 것.

### 1.2 출력 (COLMAP text format)

`<output_dir>/sparse/0/` 에 3개 텍스트 파일:

```
sparse/0/
├── cameras.txt    # 1 OPENCV W H fx fy cx cy k1 k2 p1 p2
├── images.txt     # image_id qw qx qy qz tx ty tz cam_id name + (empty POINTS2D line)
└── points3D.txt   # point_id X Y Z R G B ERROR (TRACK 비움)
```

3DGS / 2DGS 의 `colmap_loader.py` 가 text 포맷을 그대로 인식 → `--source_path <pose_dir>` 으로 입력 가능.

### 1.3 좌표계 / 규약 변환

| 항목 | 입력 (MASt3R-SLAM / TUM 관행) | 출력 (COLMAP) | 변환 |
|---|---|---|---|
| Quaternion 순서 | `(qx, qy, qz, qw)` | `(qw, qx, qy, qz)` | reorder |
| Pose 방향 | camera-to-world (`T_wc`) | world-to-camera (`T_cw`) | `R_cw = R_wc.T`, `t_cw = -R_cw @ t_wc` |
| Rotation 표현 | Hamilton quaternion | Hamilton quaternion (rotation matrix 경유) | quaternion → R → quaternion |

이 변환은 adapter 내부 `quat_xyzw_to_wxyz`, `quat_to_R`, `R_to_quat`, `invert_pose_wc_to_cw` 함수에서 수행.

### 1.4 Synthetic point fallback

`--pointcloud` 미지정 또는 파일 없음 → trajectory의 모든 카메라 중심 bounding box를 1.5배 확장한 영역에서 `--synthetic-n` (default 50,000) 개 균등 sampling. RGB = 128 (회색).

이는 3DGS / 2DGS의 **Gaussian seed 초기화**를 위한 최소 요구사항. 실제 sparse pointmap이 있으면 그 쪽이 항상 우선.

### 1.5 호스팅 결정

본 어댑터는 numpy + plyfile 만 필요 → **별도 image 불필요**. `ars/m7_mast3r_slam:latest` 컨테이너에 이미 두 의존성이 포함되어 있으므로 같은 image를 재활용:

```bash
docker run --rm \
    -v ./data:/data \
    -v ./experiments/adapters:/adapters \
    ars/m7_mast3r_slam:latest \
    python /adapters/mast3r_slam_to_colmap.py \
        --trajectory /data/outputs/P9/I-1/run-01/pose_native/trajectory.txt \
        --intrinsics /data/sites/I-1/calib/intrinsics.json \
        --frames-dir /data/sites/I-1/runs/run-01/frames \
        --pointcloud /data/outputs/P9/I-1/run-01/pose_native/points.ply \
        --output /data/outputs/P9/I-1/run-01/pose/sparse/0
```

[run_pipeline_p9.sh](../scripts/run_pipeline_p9.sh) Stage 2가 이 호출을 wrapper.

### 1.6 검증

- COLMAP-format 텍스트는 `colmap model_converter --input_path sparse/0 --output_path sparse/0 --output_type BIN` 으로 binary 변환 후 `colmap gui`로 시각 검증 가능 (선택).
- 3DGS/2DGS의 dataset_readers 가 view 수와 sparse points 를 출력 → run_pipeline_*.sh의 로그에서 "Reading Training/Test View" 라인 확인.

### 1.7 Known limitations

| 한계 | 영향 | 대응 |
|---|---|---|
| Image-trajectory 매칭은 **순서 기반 1:1 가정** | MASt3R-SLAM이 frame을 dropping 하거나 keyframe만 출력하면 mismatch | timestamp-aware 매칭으로 확장 (Tier 3) |
| TRACK[] 정보 누락 | 3DGS/2DGS는 sparse point만 seed로 사용하므로 영향 미미 | — |
| Synthetic fallback은 quality 낮음 | 학습 초기 수렴 느림 | 실 PLY가 있을 때만 사용 권장 |
| Distortion 모델 fixed = OPENCV | 어안렌즈 / fisheye 미지원 | 추후 OPENCV_FISHEYE 분기 추가 |

---

## 2. `colmap_to_intrinsics.py` — P1 self-calibration → site-shared intrinsics

P1 (M1 COLMAP) 의 self-calibration 결과 (sparse/0/cameras.{txt,bin}) 로부터 OPENCV 8-param intrinsics JSON 을 추출하여, **P9 (M7 MASt3R-SLAM) 의 intrinsics 입력으로 재사용**한다. 체커보드 calibration 없이 site 단위 self-calib 만으로 pilot 진입을 가능하게 하는 어댑터.

### 2.1 입력 / 출력

| 항목 | 경로 (예시) | 포맷 |
|---|---|---|
| 입력 | `data/outputs/P1/{site}/{run}/pose/sparse/0/cameras.bin` (또는 `.txt`) | COLMAP camera model |
| 출력 | `data/sites/{site}/calib/intrinsics.json` | OPENCV 8-param JSON (`mast3r_slam_to_colmap.py` 의 `load_intrinsics()` schema 호환) |

지원 모델 — OPENCV / PINHOLE / SIMPLE_PINHOLE / SIMPLE_RADIAL / RADIAL / FULL_OPENCV. 입력 model 이 PINHOLE 류일 때 부족한 distortion 항은 0 으로 채움 (downstream 어댑터가 OPENCV 8-param 을 요구).

### 2.2 모델별 변환 규칙

| COLMAP 입력 model | 추출 규칙 |
|---|---|
| OPENCV (4) | fx, fy, cx, cy, k1, k2, p1, p2 그대로 |
| PINHOLE (1) | fx, fy, cx, cy; k=p=0 |
| SIMPLE_PINHOLE (0) | f → fx=fy; k=p=0 |
| SIMPLE_RADIAL (2) | f → fx=fy; k1=k, k2=p1=p2=0 |
| RADIAL (3) | f → fx=fy; k1,k2 보존; p=0 |
| FULL_OPENCV (6) | 처음 8-param 추출; k3..k6 drop (warning) |
| OPENCV_FISHEYE 등 | 미지원 — ValueError |

### 2.3 호출 예시

```bash
# P1 stage 1 (COLMAP) 종료 후 사이트 공유 intrinsics 추출
docker run --rm \
    -v "$DATA_ROOT":/data \
    -v "$(pwd)/experiments/adapters":/adapters \
    ars/m1_colmap:latest \
    python /adapters/colmap_to_intrinsics.py \
        --cameras /data/outputs/P1/I-1/run-01/pose/sparse/0/cameras.bin \
        --output  /data/sites/I-1/calib/intrinsics.json

# 이후 P9 호출 시 동일 JSON 이 자동 참조 (mast3r_slam_to_colmap.py 입력)
```

`run_pipeline_p1.sh` 의 Stage 3 후속 wrapper 로 호출하면 P9 진입 직전 intrinsics 자동 준비.

### 2.4 호스팅

`numpy` 만 필요 → 별도 image 불필요. `ars/m1_colmap` 컨테이너 또는 host python 어느 쪽이든 가능.

### 2.5 Known limitations

| 한계 | 영향 | 대응 |
|---|---|---|
| Single-camera 가정 (첫 entry 만) | 다중 camera site 미지원 | run_pipeline_p1.sh 의 `--ImageReader.single_camera 1` default ON |
| Fisheye 미지원 | 어안렌즈 site 에서 사용 불가 | OPENCV_FISHEYE 분기는 future work |
| Self-calib 한계 | 극단 distortion site 에서 부정확 | 별도 calibration session (Tier 3) |

---

## 3. Future Adapters (Tier 3 예정)

| 후보 | 목적 |
|---|---|
| `droid_slam_to_colmap.py` | M5 DROID-SLAM → COLMAP-format (P6 stage 1→2) |
| `dpv_slam_to_colmap.py` | M6 DPV-SLAM → COLMAP-format (P7 stage 1→2) |
| `dust3r_to_colmap.py` | M3 DUSt3R global alignment → COLMAP (P4 stage 1→2) |
| `mast3r_to_colmap.py` | M4 MASt3R global → COLMAP (P5 stage 1→2) |
| `colmap_to_bev.py` / `gaussian_to_bev.py` | Tier 3 BEV occupancy grid 변환 |

---

## 4. Cross-reference

- Pipeline 호출 wrapper: [`scripts/run_pipeline_p1.sh`](../scripts/run_pipeline_p1.sh) · [`scripts/run_pipeline_p9.sh`](../scripts/run_pipeline_p9.sh)
- 입력 데이터 layout: [`data/README.md`](../data/README.md)
- 가설 매핑: [PAPER_OUTLINE.md §3.3 Table 1b](../../PAPER_OUTLINE.md)
- M1 method README: [`docker/m1_colmap/README.md`](../docker/m1_colmap/README.md)
- M7 method README: [`docker/m7_mast3r_slam/README.md`](../docker/m7_mast3r_slam/README.md)
- M9 method README: [`docker/m9_2dgs/README.md`](../docker/m9_2dgs/README.md)
