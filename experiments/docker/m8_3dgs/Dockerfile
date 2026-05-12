# =============================================================================
# M8 3DGS — 3D Gaussian Splatting (representation stage for P1 H-Worst pipeline)
# Source: https://github.com/graphdeco-inria/gaussian-splatting (Kerbl23, LR-[8])
# Build:  docker build -t ars/m8_3dgs:latest .
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
# 3DGS source + CUDA submodules
# ------------------------------------------------------------
WORKDIR /opt
RUN git clone --recursive https://github.com/graphdeco-inria/gaussian-splatting.git gaussian_splatting

WORKDIR /opt/gaussian_splatting

# Common 3DGS python deps
RUN pip install \
        plyfile==1.0.3 \
        tqdm \
        tensorboard \
        opencv-python==4.9.0.80 \
        Pillow==10.2.0 \
        numpy==1.26.4 \
        scipy==1.11.4 \
        joblib

# ------------------------------------------------------------
# Build CUDA submodules
#   PEP 517 build isolation은 setup.py가 'import torch'할 때
#   build env에서 torch를 격리시켜 ModuleNotFoundError 유발.
#   --no-build-isolation 으로 이미 설치된 torch 2.1+cu118 사용.
# ------------------------------------------------------------
RUN pip install --no-build-isolation ./submodules/diff-gaussian-rasterization

RUN pip install --no-build-isolation ./submodules/simple-knn

# Optional: fused-ssim if repo includes it
RUN if [ -d ./submodules/fused-ssim ]; then \
        pip install --no-build-isolation ./submodules/fused-ssim || true; \
    fi

ENV PYTHONPATH=/opt/gaussian_splatting:$PYTHONPATH

WORKDIR /workspace
CMD ["python", "-c", "import diff_gaussian_rasterization, simple_knn; print('3DGS rasterizer + simple_knn OK')"]
