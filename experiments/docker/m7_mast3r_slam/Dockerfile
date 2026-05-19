# =============================================================================
# M7 MASt3R-SLAM — Deep-prior visual SLAM (pose stage for P9 H-Best pipeline)
# Source: https://github.com/rmurai0610/MASt3R-SLAM (Murai et al. 2025, LR-[7])
# Build:  docker build -t ars/m7_mast3r_slam:latest .
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
        ffmpeg \
        build-essential cmake ninja-build \
    && rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/bin/python3.10 /usr/local/bin/python \
 && ln -sf /usr/bin/python3.10 /usr/local/bin/python3 \
 && python -m pip install --upgrade pip setuptools wheel

# ------------------------------------------------------------
# PyTorch 2.1.0 + CUDA 11.8 (RTX 4090 SM 8.9 supported)
# ------------------------------------------------------------
RUN pip install \
        torch==2.1.0 torchvision==0.16.0 \
        --index-url https://download.pytorch.org/whl/cu118

# ------------------------------------------------------------
# MASt3R-SLAM source (recursive — pulls MASt3R / Croco submodules)
# ------------------------------------------------------------
WORKDIR /opt
RUN git clone --recursive https://github.com/rmurai0610/MASt3R-SLAM.git mast3r_slam

WORKDIR /opt/mast3r_slam

# Python dependency stack (commonly required by MASt3R/Croco ecosystem)
# Pinned conservatively to compatible Numpy/SciPy era with PyTorch 2.1.
RUN pip install \
        numpy==1.26.4 \
        scipy==1.11.4 \
        einops==0.7.0 \
        opencv-python==4.9.0.80 \
        Pillow==10.2.0 \
        matplotlib==3.8.2 \
        tqdm \
        pyyaml \
        roma \
        huggingface_hub \
        safetensors \
        gradio \
        trimesh \
        scikit-image \
        plyfile \
        evo

# lietorch: source build with --no-build-isolation 으로 본 image 의 PyTorch
# 2.1.0+cu118 사용. pip 의 prebuilt wheel 은 다른 PyTorch ABI 로 build 되어
# `undefined symbol: _ZNK3c106SymInt13toSymNodeImplEv` 같은 ABI mismatch 발생.
RUN pip install --no-cache-dir --no-build-isolation \
        git+https://github.com/princeton-vl/lietorch.git

# Editable install of MASt3R-SLAM package (per repo convention).
# If the repo lacks setup.py / pyproject.toml at root, the editable install
# falls back to PYTHONPATH-only use.
RUN pip install -e . || echo "[warn] editable install unavailable — relying on PYTHONPATH"

ENV PYTHONPATH=/opt/mast3r_slam:/opt/mast3r_slam/mast3r:/opt/mast3r_slam/croco:$PYTHONPATH

# ------------------------------------------------------------
# Weight directory mountpoint
# ------------------------------------------------------------
RUN mkdir -p /weights
ENV MAST3R_CHECKPOINT=/weights/MASt3R_ViTLarge_BaseDecoder_512_catmlpdpt_metric.pth

WORKDIR /workspace
CMD ["python", "-c", "import torch; print('torch', torch.__version__, 'cuda', torch.cuda.is_available())"]
