# =============================================================================
# M1 COLMAP — SfM (Structure-from-Motion) pose stage for P1 (H-Worst pipeline)
# Source: https://github.com/colmap/colmap (Schönberger16, LR-[1])
# Build:  docker build -t ars/m1_colmap:3.9.1 .
# =============================================================================
FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Seoul
ENV TORCH_CUDA_ARCH_LIST="8.9"
ENV CMAKE_CUDA_ARCHITECTURES="89"

# ------------------------------------------------------------
# System deps (COLMAP build deps — Ubuntu 22.04 official guide)
# ------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        git wget curl ca-certificates \
        cmake ninja-build build-essential \
        libboost-program-options-dev \
        libboost-filesystem-dev \
        libboost-graph-dev \
        libboost-system-dev \
        libeigen3-dev \
        libflann-dev \
        libfreeimage-dev \
        libmetis-dev \
        libgoogle-glog-dev \
        libgtest-dev \
        libgmock-dev \
        libsqlite3-dev \
        libglew-dev \
        qtbase5-dev \
        libqt5opengl5-dev \
        libcgal-dev \
        libceres-dev \
        libsuitesparse-dev \
        libatlas-base-dev \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# COLMAP 3.9.1
# ------------------------------------------------------------
ARG COLMAP_VERSION=3.9.1
WORKDIR /opt
RUN git clone --branch ${COLMAP_VERSION} --depth 1 \
        https://github.com/colmap/colmap.git colmap-src \
 && mkdir -p colmap-src/build \
 && cd colmap-src/build \
 && cmake .. -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CUDA_ARCHITECTURES="${CMAKE_CUDA_ARCHITECTURES}" \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
 && ninja -j"$(nproc)" \
 && ninja install \
 && cd /opt && rm -rf colmap-src

# ------------------------------------------------------------
# Default workspace + helper script
# ------------------------------------------------------------
WORKDIR /workspace

# Smoke test entrypoint — `docker run --gpus all ars/m1_colmap:3.9.1`
CMD ["colmap", "--help"]
