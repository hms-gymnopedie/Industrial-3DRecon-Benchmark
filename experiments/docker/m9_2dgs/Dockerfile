# =============================================================================
# M9 2DGS — 2D Gaussian Splatting (representation stage for P9 H-Best pipeline)
# Source: https://github.com/hbb1/2d-gaussian-splatting (Huang24, LR-[9])
# Build:  docker build -t ars/m9_2dgs:latest .
# =============================================================================
FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Seoul
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1
ENV TORCH_CUDA_ARCH_LIST="8.9"
ENV CUDA_HOME=/usr/local/cuda

# ------------------------------------------------------------
# System deps
# ------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        git wget curl ca-certificates \
        python3.10 python3.10-venv python3.10-dev python3-pip \
        libgl1 libglib2.0-0 libgomp1 libsm6 libxext6 libxrender1 \
        build-essential cmake ninja-build \
    && rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/bin/python3.10 /usr/local/bin/python \
 && ln -sf /usr/bin/python3.10 /usr/local/bin/python3 \
 && python -m pip install --upgrade pip setuptools wheel

# ------------------------------------------------------------
# PyTorch 2.1.0 + CUDA 11.8
# ------------------------------------------------------------
RUN pip install \
        torch==2.1.0 torchvision==0.16.0 \
        --index-url https://download.pytorch.org/whl/cu118

# ------------------------------------------------------------
# 2DGS source + CUDA submodules
# ------------------------------------------------------------
WORKDIR /opt
RUN git clone --recursive https://github.com/hbb1/2d-gaussian-splatting.git two_dgs

WORKDIR /opt/two_dgs

# Common 2DGS python deps (a superset of 3DGS due to native mesh export)
RUN pip install \
        plyfile==1.0.3 \
        tqdm \
        tensorboard \
        opencv-python==4.9.0.80 \
        Pillow==10.2.0 \
        numpy==1.26.4 \
        scipy==1.11.4 \
        trimesh==4.1.7 \
        open3d==0.18.0 \
        scikit-image==0.22.0 \
        mediapy

# ------------------------------------------------------------
# Build CUDA submodules
#   PEP 517 build isolation 회피 (setup.py가 build 시점에 import torch).
#   --no-build-isolation 으로 이미 설치된 torch 2.1+cu118 사용.
# ------------------------------------------------------------
RUN pip install --no-build-isolation ./submodules/diff-surfel-rasterization

RUN pip install --no-build-isolation ./submodules/simple-knn

ENV PYTHONPATH=/opt/two_dgs:$PYTHONPATH

WORKDIR /workspace
CMD ["python", "-c", "import diff_surfel_rasterization, simple_knn; print('2DGS surfel rasterizer + simple_knn OK')"]
