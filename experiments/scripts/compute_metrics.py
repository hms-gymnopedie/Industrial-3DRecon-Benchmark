#!/usr/bin/env python3
# =============================================================================
# compute_metrics.py
#   Pipeline 실행 결과로부터 metrics.json 생성.
#
# 측정 항목 (Tier 2 범위):
#   - wall_time_pose_sec, wall_time_adapter_sec, wall_time_rep_sec, wall_time_total_sec
#   - n_gaussians (3DGS/2DGS recon → point_cloud.ply의 vertex 수)
#   - psnr / ssim / lpips (3DGS/2DGS의 --eval 단계 출력 디렉토리에서 파싱)
#   - n_images, n_pose_estimated (가능한 경우)
#
# 제외 (Tier 3 deferred):
#   - Chamfer distance (GT mesh 부재 산업 site에서 불가)
#   - BEV-IoU (mesh extraction + occupancy grid 변환 필요)
#   - VRAM peak (런타임 sampling 필요 — 별도 nvidia-smi monitor)
#   - RRT* success rate (IsaacSim 통합 필요)
#
# 산출 결과는 site-pair (P1 vs P9, P9 vs library control 등) 비교에 사용.
# =============================================================================
"""Aggregate metrics from a single pipeline run into metrics.json."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Optional


def parse_psnr_ssim_from_results_json(recon_dir: Path) -> dict:
    """3DGS / 2DGS의 metrics.py 산출물 (results.json) 파싱.

    구조 예시 (3DGS upstream):
      { "ours_30000": { "SSIM": 0.812, "PSNR": 24.31, "LPIPS": 0.182 } }
    """
    candidate = recon_dir / "results.json"
    if not candidate.exists():
        return {}
    try:
        with open(candidate) as f:
            data = json.load(f)
    except Exception as e:
        sys.stderr.write(f"[warn] results.json 파싱 실패: {e}\n")
        return {}

    # Pick the largest iteration key (e.g., ours_30000)
    best_key = None
    best_iter = -1
    for k in data.keys():
        m = re.search(r"(\d+)", k)
        if not m:
            continue
        it = int(m.group(1))
        if it > best_iter:
            best_iter = it
            best_key = k
    if best_key is None:
        return {}
    sub = data[best_key]
    out = {}
    for src, dst in (("PSNR", "psnr"), ("SSIM", "ssim"), ("LPIPS", "lpips")):
        if src in sub:
            try:
                out[dst] = float(sub[src])
            except Exception:
                pass
    out["eval_iteration"] = best_iter
    return out


def count_gaussians(recon_dir: Path) -> Optional[int]:
    """3DGS/2DGS의 point_cloud.ply에서 vertex 수 카운트.

    경로 패턴: recon_dir/point_cloud/iteration_*/point_cloud.ply  (3DGS)
              recon_dir/point_cloud/iteration_*/point_cloud.ply  (2DGS, 동일)
    """
    plys = sorted((recon_dir / "point_cloud").glob("iteration_*/point_cloud.ply"))
    if not plys:
        return None
    target = plys[-1]
    try:
        with open(target, "rb") as f:
            # PLY header — read first ~2KB to find vertex count.
            head = f.read(2048).decode("utf-8", errors="ignore")
        m = re.search(r"element vertex (\d+)", head)
        if m:
            return int(m.group(1))
    except Exception as e:
        sys.stderr.write(f"[warn] PLY 헤더 파싱 실패: {e}\n")
    return None


def count_n_images_from_cameras_json(recon_dir: Path) -> Optional[int]:
    """3DGS/2DGS의 cameras.json에서 등록된 view 수."""
    p = recon_dir / "cameras.json"
    if not p.exists():
        return None
    try:
        with open(p) as f:
            arr = json.load(f)
        return len(arr) if isinstance(arr, list) else None
    except Exception:
        return None


def main() -> int:
    ap = argparse.ArgumentParser(description="Aggregate metrics for one pipeline run.")
    ap.add_argument("--pipeline", required=True, help="P1 / P9 ...")
    ap.add_argument("--site", required=True)
    ap.add_argument("--run", required=True)
    ap.add_argument("--recon-dir", required=True, help="3DGS/2DGS의 --model_path 디렉토리")
    ap.add_argument("--t-pose", type=int, default=0, help="pose stage wall time (sec)")
    ap.add_argument("--t-rep", type=int, default=0, help="representation stage wall time (sec)")
    ap.add_argument("--t-adapter", type=int, default=0, help="(P9 only) adapter wall time (sec)")
    ap.add_argument("--output", required=True, help="출력 metrics.json 경로")
    args = ap.parse_args()

    recon_dir = Path(args.recon_dir)

    metrics: dict = {
        "pipeline": args.pipeline,
        "site": args.site,
        "run": args.run,
        "wall_time_pose_sec": args.t_pose,
        "wall_time_adapter_sec": args.t_adapter,
        "wall_time_rep_sec": args.t_rep,
        "wall_time_total_sec": args.t_pose + args.t_adapter + args.t_rep,
    }

    eval_metrics = parse_psnr_ssim_from_results_json(recon_dir)
    metrics.update(eval_metrics)

    n_gauss = count_gaussians(recon_dir)
    if n_gauss is not None:
        metrics["n_gaussians"] = n_gauss

    n_views = count_n_images_from_cameras_json(recon_dir)
    if n_views is not None:
        metrics["n_views_registered"] = n_views

    # Status flag — at least one of (psnr, n_gaussians) should exist for a 'successful' run.
    metrics["status"] = "ok" if ("psnr" in metrics or "n_gaussians" in metrics) else "incomplete"

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w") as f:
        json.dump(metrics, f, indent=2, ensure_ascii=False)

    # Print summary table to stdout
    print(f"\n[metrics.json] {out_path}")
    print("-" * 56)
    for k in (
        "pipeline", "site", "run", "status",
        "wall_time_pose_sec", "wall_time_adapter_sec", "wall_time_rep_sec", "wall_time_total_sec",
        "psnr", "ssim", "lpips", "eval_iteration",
        "n_gaussians", "n_views_registered",
    ):
        if k in metrics:
            v = metrics[k]
            if isinstance(v, float):
                print(f"  {k:<28} {v:>12.4f}")
            else:
                print(f"  {k:<28} {v!s:>12}")
    print("-" * 56)
    return 0


if __name__ == "__main__":
    sys.exit(main())
