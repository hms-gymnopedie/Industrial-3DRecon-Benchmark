#!/usr/bin/env python3
# =============================================================================
# colmap_to_intrinsics.py
#   COLMAP sparse reconstruction (cameras.txt 또는 cameras.bin) → OPENCV
#   intrinsics JSON (mast3r_slam_to_colmap.py 어댑터가 소비하는 schema).
#
# 본 어댑터는 결정 (α): "P1 (M1 COLMAP) self-calibration 결과로부터 카메라
# 내부 파라미터를 추출하여 P9 (M7 MASt3R-SLAM) 의 intrinsics 입력으로 재사용"
# 의 구현이다. 체커보드 calibration 없이 site 단위 self-calib 만으로
# pilot 진입을 가능하게 한다.
#
# 변환:
#   COLMAP camera model  OPENCV / PINHOLE / SIMPLE_PINHOLE / SIMPLE_RADIAL /
#                        RADIAL 5종 지원. OPENCV 외 모델은 fx,fy,cx,cy 만
#                        추출하고 k/p 는 0 으로 채움 (downstream 어댑터는
#                        OPENCV 8-param 을 요구).
#   출력 schema:         data/README.md §4 + mast3r_slam_to_colmap.py
#                        load_intrinsics() 가 검증하는 필드 집합.
#
# Usage (P1 결과 → site 공유 calib 으로 export):
#   python colmap_to_intrinsics.py \
#       --cameras  /data/outputs/P1/I-1/run-01/pose/sparse/0/cameras.bin \
#       --output   /data/sites/I-1/calib/intrinsics.json
#
# 본 호스팅:
#   numpy 만 필요. ars/m1_colmap 컨테이너 또는 host python 어느 쪽이든 가능.
#   run_pipeline_p1.sh 의 Stage 3 후속 wrapper 로 호출 권장.
# =============================================================================
"""COLMAP sparse model → OPENCV intrinsics JSON."""

from __future__ import annotations

import argparse
import json
import struct
import sys
from pathlib import Path
from typing import List


# COLMAP camera model IDs and parameter counts
# Source: https://github.com/colmap/colmap/blob/main/src/colmap/sensor/models.h
_COLMAP_MODELS = {
    0: ("SIMPLE_PINHOLE", 3),   # f, cx, cy
    1: ("PINHOLE", 4),          # fx, fy, cx, cy
    2: ("SIMPLE_RADIAL", 4),    # f, cx, cy, k
    3: ("RADIAL", 5),           # f, cx, cy, k1, k2
    4: ("OPENCV", 8),           # fx, fy, cx, cy, k1, k2, p1, p2
    5: ("OPENCV_FISHEYE", 8),   # fx, fy, cx, cy, k1, k2, k3, k4
    6: ("FULL_OPENCV", 12),     # fx, fy, cx, cy, k1, k2, p1, p2, k3, k4, k5, k6
    7: ("FOV", 5),              # fx, fy, cx, cy, omega
    8: ("SIMPLE_RADIAL_FISHEYE", 4),
    9: ("RADIAL_FISHEYE", 5),
    10: ("THIN_PRISM_FISHEYE", 12),
}

_NAME_TO_ID = {v[0]: k for k, v in _COLMAP_MODELS.items()}


def _params_to_opencv(model: str, params: List[float]) -> dict:
    """COLMAP camera model parameters → OPENCV 8-param representation.

    Output fields: fx, fy, cx, cy, k1, k2, p1, p2.
    """
    p = list(params)
    if model == "OPENCV":
        fx, fy, cx, cy, k1, k2, p1, p2 = p[:8]
    elif model == "PINHOLE":
        fx, fy, cx, cy = p[:4]
        k1 = k2 = p1 = p2 = 0.0
    elif model == "SIMPLE_PINHOLE":
        f, cx, cy = p[:3]
        fx = fy = f
        k1 = k2 = p1 = p2 = 0.0
    elif model == "SIMPLE_RADIAL":
        f, cx, cy, k = p[:4]
        fx = fy = f
        k1, k2 = k, 0.0
        p1 = p2 = 0.0
    elif model == "RADIAL":
        f, cx, cy, k1, k2 = p[:5]
        fx = fy = f
        p1 = p2 = 0.0
    elif model == "FULL_OPENCV":
        # FULL_OPENCV 12-param → OPENCV 8-param projection (drops k3..k6)
        fx, fy, cx, cy, k1, k2, p1, p2 = p[:8]
        sys.stderr.write(
            "[warn] FULL_OPENCV → OPENCV 변환에서 k3..k6 무시됨. "
            "정밀 distortion 필요 시 calibration 재실시 권장.\n"
        )
    else:
        raise ValueError(
            f"지원되지 않는 COLMAP camera model: {model} "
            f"(지원: OPENCV / PINHOLE / SIMPLE_PINHOLE / SIMPLE_RADIAL / "
            f"RADIAL / FULL_OPENCV)"
        )
    return {
        "fx": float(fx), "fy": float(fy),
        "cx": float(cx), "cy": float(cy),
        "k1": float(k1), "k2": float(k2),
        "p1": float(p1), "p2": float(p2),
    }


def parse_cameras_txt(path: Path) -> dict:
    """COLMAP cameras.txt 파싱 → (model, width, height, params).

    cameras.txt 포맷:
        # comment lines start with '#'
        CAMERA_ID  MODEL_NAME  WIDTH  HEIGHT  PARAM_1  PARAM_2  ...
    """
    with open(path, "r") as f:
        lines = [ln.strip() for ln in f if ln.strip() and not ln.strip().startswith("#")]
    if not lines:
        raise ValueError(f"cameras.txt 비어 있음: {path}")
    # 다중 camera 시 첫 번째 (CAMERA_ID = 1) 사용 — single_camera 가정
    fields = lines[0].split()
    if len(fields) < 5:
        raise ValueError(f"cameras.txt 행 포맷 오류: {fields}")
    _cam_id = int(fields[0])
    model = fields[1]
    width = int(fields[2])
    height = int(fields[3])
    params = [float(x) for x in fields[4:]]
    return {"model": model, "width": width, "height": height, "params": params}


def parse_cameras_bin(path: Path) -> dict:
    """COLMAP cameras.bin 파싱 (single-camera 첫 항목만).

    Binary layout per camera:
        uint64 num_cameras (header)
        for each camera:
          uint32 camera_id
          int32  model_id
          uint64 width
          uint64 height
          float64 params[ n_params(model_id) ]
    """
    with open(path, "rb") as f:
        buf = f.read()
    if len(buf) < 8:
        raise ValueError(f"cameras.bin 헤더 부족: {path}")
    off = 0
    num_cameras = struct.unpack_from("<Q", buf, off)[0]
    off += 8
    if num_cameras == 0:
        raise ValueError("cameras.bin 의 num_cameras == 0")
    # 첫 번째 camera 만 읽음.
    # COLMAP cameras.bin 의 표준 layout:
    #   camera_id : uint32 (4 bytes)
    #   model_id  : int32  (4 bytes)
    #   width     : uint64 (8 bytes)
    #   height    : uint64 (8 bytes)
    #   params[n] : float64 each (8 bytes per param, n depends on model)
    cam_id, model_id = struct.unpack_from("<Ii", buf, off)
    off += 8
    width, height = struct.unpack_from("<QQ", buf, off)
    off += 16
    if model_id not in _COLMAP_MODELS:
        raise ValueError(f"알 수 없는 COLMAP model_id={model_id} in {path}")
    model_name, n_params = _COLMAP_MODELS[model_id]
    params = list(struct.unpack_from(f"<{n_params}d", buf, off))
    off += 8 * n_params
    return {"model": model_name, "width": int(width), "height": int(height), "params": params}


def main() -> int:
    ap = argparse.ArgumentParser(
        description="COLMAP cameras.{txt,bin} → OPENCV intrinsics JSON",
    )
    ap.add_argument(
        "--cameras", required=True,
        help="COLMAP sparse/0/cameras.{txt|bin} 경로",
    )
    ap.add_argument(
        "--output", required=True,
        help="출력 intrinsics.json 경로 (data/sites/{site}/calib/intrinsics.json)",
    )
    ap.add_argument(
        "--force-opencv", action="store_true",
        help="입력 model 이 PINHOLE / SIMPLE_PINHOLE 일 때도 OPENCV 8-param 으로 강제 변환 (k=p=0).",
    )
    args = ap.parse_args()

    in_path = Path(args.cameras)
    if not in_path.exists():
        sys.exit(f"[fatal] 입력 파일 없음: {in_path}")

    print(f"[1/3] COLMAP cameras 파싱: {in_path}")
    if in_path.suffix == ".txt":
        parsed = parse_cameras_txt(in_path)
    elif in_path.suffix == ".bin":
        parsed = parse_cameras_bin(in_path)
    else:
        sys.exit(f"[fatal] 지원되지 않는 확장자: {in_path.suffix} (txt|bin)")

    print(f"      → model={parsed['model']}  W={parsed['width']}  H={parsed['height']}  "
          f"params={len(parsed['params'])}")

    print(f"[2/3] OPENCV 8-param 변환")
    opencv_params = _params_to_opencv(parsed["model"], parsed["params"])
    intrinsics = {
        "model": "OPENCV",
        "width": parsed["width"],
        "height": parsed["height"],
        **opencv_params,
        "_source": f"colmap:{parsed['model']}",
    }
    print(f"      → fx={opencv_params['fx']:.2f}  fy={opencv_params['fy']:.2f}  "
          f"cx={opencv_params['cx']:.2f}  cy={opencv_params['cy']:.2f}")
    if any(opencv_params[k] != 0.0 for k in ("k1", "k2", "p1", "p2")):
        print(f"      → distortion: k1={opencv_params['k1']:.4f}  k2={opencv_params['k2']:.4f}  "
              f"p1={opencv_params['p1']:.4f}  p2={opencv_params['p2']:.4f}")
    else:
        print(f"      → distortion: zero (input model={parsed['model']} or no distortion)")

    print(f"[3/3] 출력 JSON 쓰기: {args.output}")
    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w") as f:
        json.dump(intrinsics, f, indent=2, ensure_ascii=False)

    print()
    print("================================================================")
    print(f"  intrinsics.json 작성 완료: {out_path}")
    print(f"  schema 검증: mast3r_slam_to_colmap.py load_intrinsics() 호환")
    print("================================================================")
    return 0


if __name__ == "__main__":
    sys.exit(main())
