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
# PyPI dependency 일괄 — mast3r-slam + mast3r/retrieval + dust3r/croco 의 합집합.
# silent skip 회피를 위해 single RUN 으로 묶음 (한 줄이라도 fail 시 build 실패).
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
        evo \
        faiss-cpu \
        timm \
        kapture \
        kapture-localization \
        pyflann-py3 \
        pypose \
        kornia \
        omegaconf

# asmk: naver/mast3r 공식 install 절차 (PyPI 미존재 — Cython source build).
# `pip install git+` 는 .pyx → .so 컴파일 결과를 site-packages 에 올리지 못함.
# 정식 절차: clone → cython/ 안에서 setup.py build_ext --inplace.
# 결과 폴더를 PYTHONPATH 로 직접 노출 (ENV 갱신 아래 참조).
RUN pip install --no-cache-dir cython && \
    cd /opt && \
    git clone https://github.com/jenicek/asmk.git && \
    cd asmk/cython && \
    python setup.py build_ext --inplace

# lietorch: source build with --no-build-isolation 으로 본 image 의 PyTorch
# 2.1.0+cu118 사용. pip 의 prebuilt wheel 은 다른 PyTorch ABI 로 build 되어
# `undefined symbol: _ZNK3c106SymInt13toSymNodeImplEv` 같은 ABI mismatch 발생.
RUN pip install --no-cache-dir --no-build-isolation \
        git+https://github.com/princeton-vl/lietorch.git

# Editable install of MASt3R-SLAM package (per repo convention).
# Silent fail (|| echo) 제거 — setup.py 가 실패하면 dependency chain 누락으로
# 런타임 ModuleNotFoundError 가 cascade. 명시적 build 실패가 더 진단 쉬움.
# 만약 repo 에 setup.py/pyproject.toml 부재 시 PYTHONPATH 의존 — 단 그 경우는
# Dockerfile 측에서 별도 확인 필요 (현재 mast3r-slam upstream 은 pyproject.toml 보유).
RUN pip install --no-build-isolation -e .

# MASt3R-SLAM 의 mast3r / dust3r 등은 thirdparty/ 아래에 nested submodule 로 위치.
# import mast3r.xxx 가 가능하려면 그 부모 디렉토리가 PYTHONPATH 에 있어야 함.
# asmk 도 /opt/asmk 에 cython source build 후 PYTHONPATH 노출.
ENV PYTHONPATH=/opt/mast3r_slam:/opt/mast3r_slam/thirdparty/mast3r:/opt/mast3r_slam/thirdparty/mast3r/dust3r:/opt/mast3r_slam/thirdparty/in3d:/opt/asmk:$PYTHONPATH

# ------------------------------------------------------------
# Weight directory mountpoint
# ------------------------------------------------------------
RUN mkdir -p /weights
ENV MAST3R_CHECKPOINT=/weights/MASt3R_ViTLarge_BaseDecoder_512_catmlpdpt_metric.pth

WORKDIR /workspace
CMD ["python", "-c", "import torch; print('torch', torch.__version__, 'cuda', torch.cuda.is_available())"]
