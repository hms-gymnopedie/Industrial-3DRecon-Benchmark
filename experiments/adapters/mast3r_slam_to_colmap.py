#!/usr/bin/env python3
# =============================================================================
# mast3r_slam_to_colmap.py
#   MASt3R-SLAM native trajectory output → COLMAP text format
#
# 변환 항목:
#   1. Trajectory (TUM format: ts tx ty tz qx qy qz qw)  →  images.txt
#   2. Intrinsics (OPENCV JSON)                          →  cameras.txt
#   3. Sparse pointcloud (PLY, 선택)                     →  points3D.txt
#
# 좌표계/규약 변환:
#   - Quaternion: TUM (qx, qy, qz, qw) → COLMAP (qw, qx, qy, qz)
#   - Pose: TUM은 camera-to-world (T_wc); COLMAP은 world-to-camera (T_cw) → invert
#
# COLMAP 포맷은 text 우선 (cameras.txt / images.txt / points3D.txt).
# 3DGS / 2DGS의 dataset reader는 text/binary 둘 다 지원하며 text 사용 가능.
#
# Usage:
#   python mast3r_slam_to_colmap.py \
#       --trajectory   /data/outputs/P9/I-1/run-01/pose_native/trajectory.txt \
#       --intrinsics   /data/sites/I-1/calib/intrinsics.json \
#       --frames-dir   /data/sites/I-1/runs/run-01/frames \
#       --pointcloud   /data/outputs/P9/I-1/run-01/pose_native/points.ply  \
#       --output       /data/outputs/P9/I-1/run-01/pose/sparse/0 \
#       --max-points   100000
# =============================================================================
"""MASt3R-SLAM → COLMAP-format adapter.

Output schema follows the COLMAP reconstruction text format documented at
https://colmap.github.io/format.html . Both `3DGS` and `2DGS` Scene loaders
accept this format directly through their `colmap_loader` modules.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from typing import List, Tuple

import numpy as np


# -----------------------------------------------------------------------------
# Quaternion / pose utilities
# -----------------------------------------------------------------------------
def quat_xyzw_to_wxyz(q_xyzw: np.ndarray) -> np.ndarray:
    """TUM (x, y, z, w) → COLMAP (w, x, y, z)."""
    qx, qy, qz, qw = q_xyzw
    return np.array([qw, qx, qy, qz], dtype=np.float64)


def quat_to_R(q_wxyz: np.ndarray) -> np.ndarray:
    """Hamilton convention (w, x, y, z)."""
    w, x, y, z = q_wxyz
    return np.array(
        [
            [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
            [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
            [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)],
        ],
        dtype=np.float64,
    )


def R_to_quat(R: np.ndarray) -> np.ndarray:
    """Rotation matrix → (w, x, y, z). Stable variant (Shoemake)."""
    m00, m01, m02 = R[0]
    m10, m11, m12 = R[1]
    m20, m21, m22 = R[2]
    tr = m00 + m11 + m22
    if tr > 0:
        s = np.sqrt(tr + 1.0) * 2.0
        qw = 0.25 * s
        qx = (m21 - m12) / s
        qy = (m02 - m20) / s
        qz = (m10 - m01) / s
    elif (m00 > m11) and (m00 > m22):
        s = np.sqrt(1.0 + m00 - m11 - m22) * 2.0
        qw = (m21 - m12) / s
        qx = 0.25 * s
        qy = (m01 + m10) / s
        qz = (m02 + m20) / s
    elif m11 > m22:
        s = np.sqrt(1.0 + m11 - m00 - m22) * 2.0
        qw = (m02 - m20) / s
        qx = (m01 + m10) / s
        qy = 0.25 * s
        qz = (m12 + m21) / s
    else:
        s = np.sqrt(1.0 + m22 - m00 - m11) * 2.0
        qw = (m10 - m01) / s
        qx = (m02 + m20) / s
        qy = (m12 + m21) / s
        qz = 0.25 * s
    return np.array([qw, qx, qy, qz], dtype=np.float64)


def invert_pose_wc_to_cw(R_wc: np.ndarray, t_wc: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
    """camera-to-world (T_wc) → world-to-camera (T_cw)."""
    R_cw = R_wc.T
    t_cw = -R_cw @ t_wc
    return R_cw, t_cw


# -----------------------------------------------------------------------------
# Input parsers
# -----------------------------------------------------------------------------
def load_trajectory_tum(path: Path) -> List[Tuple[float, np.ndarray, np.ndarray]]:
    """TUM format: ts tx ty tz qx qy qz qw (per line, '#' = comment).

    Returns list of (timestamp, t_wc(3,), q_wxyz(4,))."""
    out = []
    with open(path, "r") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            toks = line.split()
            if len(toks) < 8:
                continue
            ts = float(toks[0])
            t_wc = np.array([float(toks[1]), float(toks[2]), float(toks[3])], dtype=np.float64)
            q_xyzw = np.array([float(toks[4]), float(toks[5]), float(toks[6]), float(toks[7])], dtype=np.float64)
            out.append((ts, t_wc, quat_xyzw_to_wxyz(q_xyzw)))
    if not out:
        raise RuntimeError(f"trajectory empty or unparsable: {path}")
    return out


def load_intrinsics(path: Path) -> dict:
    with open(path, "r") as f:
        d = json.load(f)
    required = ["model", "width", "height", "fx", "fy", "cx", "cy"]
    for k in required:
        if k not in d:
            raise KeyError(f"intrinsics missing key: {k}")
    if d["model"] != "OPENCV":
        raise ValueError(f"intrinsics model must be OPENCV, got {d['model']}")
    for k in ("k1", "k2", "p1", "p2"):
        d.setdefault(k, 0.0)
    return d


def load_pointcloud_ply(path: Path) -> Tuple[np.ndarray, np.ndarray]:
    """Returns (xyz [N,3], rgb [N,3] uint8). RGB defaults to 128 if absent."""
    try:
        from plyfile import PlyData
    except ImportError:
        sys.exit("[fatal] plyfile 모듈 필요 — m7_mast3r_slam 컨테이너에 이미 포함.")
    ply = PlyData.read(str(path))
    v = ply["vertex"].data
    xyz = np.stack([np.asarray(v["x"]), np.asarray(v["y"]), np.asarray(v["z"])], axis=1).astype(np.float64)
    if all(k in v.dtype.names for k in ("red", "green", "blue")):
        rgb = np.stack([np.asarray(v["red"]), np.asarray(v["green"]), np.asarray(v["blue"])], axis=1).astype(np.uint8)
    else:
        rgb = np.full((xyz.shape[0], 3), 128, dtype=np.uint8)
    return xyz, rgb


# -----------------------------------------------------------------------------
# Frame name matching
# -----------------------------------------------------------------------------
def list_frames(frames_dir: Path) -> List[str]:
    return sorted(p.name for p in frames_dir.iterdir() if p.suffix.lower() == ".png")


def match_trajectory_to_frames(
    traj: List[Tuple[float, np.ndarray, np.ndarray]],
    frame_names: List[str],
) -> List[Tuple[str, np.ndarray, np.ndarray]]:
    """1:1 순서 매칭. trajectory의 i번째 pose → frame_names[i].

    MASt3R-SLAM이 timestamp 기반 정렬을 보장한다는 가정 (실제 native output 검수 필요).
    개수가 안 맞으면 min(len) 까지 자르고 경고."""
    n = min(len(traj), len(frame_names))
    if n < len(traj) or n < len(frame_names):
        sys.stderr.write(
            f"[warn] trajectory ({len(traj)}) vs frames ({len(frame_names)}) 개수 불일치 — min({n}) 사용\n"
        )
    out = []
    for i in range(n):
        _, t_wc, q_wxyz = traj[i]
        out.append((frame_names[i], t_wc, q_wxyz))
    return out


# -----------------------------------------------------------------------------
# COLMAP text writers
# -----------------------------------------------------------------------------
def write_cameras_txt(out_path: Path, intr: dict, camera_id: int = 1) -> None:
    with open(out_path, "w") as f:
        f.write("# Camera list with one line of data per camera:\n")
        f.write("#   CAMERA_ID, MODEL, WIDTH, HEIGHT, PARAMS[]\n")
        f.write(f"# 1 camera (single_camera=1), MODEL=OPENCV → fx,fy,cx,cy,k1,k2,p1,p2\n")
        f.write(
            f"{camera_id} OPENCV {intr['width']} {intr['height']} "
            f"{intr['fx']} {intr['fy']} {intr['cx']} {intr['cy']} "
            f"{intr['k1']} {intr['k2']} {intr['p1']} {intr['p2']}\n"
        )


def write_images_txt(
    out_path: Path,
    matched: List[Tuple[str, np.ndarray, np.ndarray]],
    camera_id: int = 1,
) -> None:
    """Each image entry = 2 lines: header + points2D (empty for this adapter)."""
    with open(out_path, "w") as f:
        f.write("# Image list with two lines of data per image:\n")
        f.write("#   IMAGE_ID, QW, QX, QY, QZ, TX, TY, TZ, CAMERA_ID, NAME\n")
        f.write("#   POINTS2D[] as (X, Y, POINT3D_ID)\n")
        f.write(f"# Number of images: {len(matched)}\n")
        for i, (name, t_wc, q_wxyz_wc) in enumerate(matched, start=1):
            # Convert camera-to-world (T_wc) → world-to-camera (T_cw) for COLMAP.
            R_wc = quat_to_R(q_wxyz_wc)
            R_cw, t_cw = invert_pose_wc_to_cw(R_wc, t_wc)
            q_cw = R_to_quat(R_cw)
            f.write(
                f"{i} {q_cw[0]:.10f} {q_cw[1]:.10f} {q_cw[2]:.10f} {q_cw[3]:.10f} "
                f"{t_cw[0]:.10f} {t_cw[1]:.10f} {t_cw[2]:.10f} "
                f"{camera_id} {name}\n"
            )
            # Empty POINTS2D line (sparse keypoints not provided by MASt3R-SLAM trajectory).
            f.write("\n")


def write_points3D_txt(
    out_path: Path,
    xyz: np.ndarray,
    rgb: np.ndarray,
    max_points: int = 100_000,
) -> None:
    n = xyz.shape[0]
    if n > max_points:
        idx = np.random.RandomState(0).choice(n, max_points, replace=False)
        xyz = xyz[idx]
        rgb = rgb[idx]
        n = max_points
    with open(out_path, "w") as f:
        f.write("# 3D point list with one line of data per point:\n")
        f.write("#   POINT3D_ID, X, Y, Z, R, G, B, ERROR, TRACK[] as (IMAGE_ID, POINT2D_IDX)\n")
        f.write(f"# Number of points: {n}\n")
        for i in range(n):
            x, y, z = xyz[i]
            r, g, b = rgb[i]
            # ERROR = 1.0 (placeholder — MASt3R-SLAM doesn't expose per-point uncertainty here).
            # TRACK[] left empty (no 2D correspondence info passed through adapter).
            f.write(f"{i + 1} {x:.6f} {y:.6f} {z:.6f} {int(r)} {int(g)} {int(b)} 1.0\n")


# -----------------------------------------------------------------------------
# Synthetic point cloud fallback
# -----------------------------------------------------------------------------
def fallback_synthetic_points(
    matched: List[Tuple[str, np.ndarray, np.ndarray]],
    n_points: int = 50_000,
) -> Tuple[np.ndarray, np.ndarray]:
    """No PLY input → scatter random points in the trajectory bounding box.

    3DGS / 2DGS는 초기 sparse points로 Gaussian seed를 생성하므로 최소 cloud가 필요.
    Trajectory 중심 ± 1.5*range 박스에 uniform sampling.
    """
    centers = np.array([t_wc for _, t_wc, _ in matched])
    cmin = centers.min(axis=0)
    cmax = centers.max(axis=0)
    span = (cmax - cmin) + 1e-6
    lo = cmin - 0.5 * span
    hi = cmax + 0.5 * span
    rng = np.random.RandomState(42)
    xyz = rng.uniform(lo, hi, size=(n_points, 3))
    rgb = np.full((n_points, 3), 128, dtype=np.uint8)
    return xyz, rgb


# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
def main() -> int:
    ap = argparse.ArgumentParser(description="MASt3R-SLAM → COLMAP-format adapter")
    ap.add_argument("--trajectory", required=True, help="TUM trajectory file")
    ap.add_argument("--intrinsics", required=True, help="OPENCV intrinsics JSON")
    ap.add_argument("--frames-dir", required=True, help="원본 PNG frames")
    ap.add_argument("--pointcloud", default=None, help="(optional) sparse PLY")
    ap.add_argument("--output", required=True, help="출력 디렉토리 (sparse/0)")
    ap.add_argument("--max-points", type=int, default=100_000)
    ap.add_argument("--synthetic-n", type=int, default=50_000, help="PLY 없을 때 fallback 포인트 수")
    args = ap.parse_args()

    out_dir = Path(args.output)
    out_dir.mkdir(parents=True, exist_ok=True)

    print(f"[1/4] trajectory 로드: {args.trajectory}")
    traj = load_trajectory_tum(Path(args.trajectory))
    print(f"      → {len(traj)} poses")

    print(f"[2/4] intrinsics 로드: {args.intrinsics}")
    intr = load_intrinsics(Path(args.intrinsics))
    print(f"      → OPENCV  {intr['width']}x{intr['height']}  fx={intr['fx']:.1f}  fy={intr['fy']:.1f}")

    print(f"[3/4] frames 디렉토리 스캔: {args.frames_dir}")
    frame_names = list_frames(Path(args.frames_dir))
    matched = match_trajectory_to_frames(traj, frame_names)
    print(f"      → {len(matched)} matched (image_id ↔ frame name)")

    write_cameras_txt(out_dir / "cameras.txt", intr)
    print(f"      written: {out_dir / 'cameras.txt'}")

    write_images_txt(out_dir / "images.txt", matched)
    print(f"      written: {out_dir / 'images.txt'}")

    print(f"[4/4] points3D 처리")
    if args.pointcloud and os.path.exists(args.pointcloud):
        xyz, rgb = load_pointcloud_ply(Path(args.pointcloud))
        print(f"      PLY 로드: {args.pointcloud} → {xyz.shape[0]} points")
    else:
        xyz, rgb = fallback_synthetic_points(matched, n_points=args.synthetic_n)
        print(f"      [warn] PLY 미제공 — synthetic bounding-box scatter {xyz.shape[0]} points")

    write_points3D_txt(out_dir / "points3D.txt", xyz, rgb, max_points=args.max_points)
    print(f"      written: {out_dir / 'points3D.txt'}")

    print()
    print("================================================================")
    print(f"  COLMAP-format output 완료: {out_dir}")
    print(f"    cameras.txt   1 camera")
    print(f"    images.txt    {len(matched)} images")
    print(f"    points3D.txt  {min(xyz.shape[0], args.max_points)} points")
    print("================================================================")
    return 0


if __name__ == "__main__":
    sys.exit(main())
