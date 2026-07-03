#!/usr/bin/env bash
# Environment setup for building PyTorch with CUDA 13.3 + cuDNN 9.22 (RTX 3050).
# Source this (don't execute) in the shell you build from:  source ./scripts/exports.sh
# Every variable is explained in docs/09-environment-variables.md

# ── CUDA paths ────────────────────────────────────────────────────────────────
export CUDA_HOME=/usr/local/cuda-13.3
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:${LD_LIBRARY_PATH:-}

export CUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda-13.3
export CMAKE_CUDA_COMPILER=/usr/local/cuda-13.3/bin/nvcc

# ── Enable CUDA + cuDNN ──────────────────────────────────────────────────────
export USE_CUDA=1
export USE_CUDNN=1

# ── GPU architecture (RTX 3050 → compute capability 8.6) ─────────────────────
export TORCH_CUDA_ARCH_LIST="8.6"

# ── Build mode: optimized + debug symbols ────────────────────────────────────
export REL_WITH_DEB_INFO=1

# ── Parallelism ──────────────────────────────────────────────────────────────
# export MAX_JOBS=$(nproc)   # all cores can OOM and hang the system
export MAX_JOBS=6            # stable ceiling on this machine

# ── Feature toggles ──────────────────────────────────────────────────────────
export BUILD_TEST=0
export USE_DISTRIBUTED=0
export USE_FLASH_ATTENTION=1

# ── Compiler flags & host compiler (gcc-15 required by CUDA 13.3) ────────────
export CFLAGS="-O3 -march=native"
export CC=/usr/bin/gcc-15
export CXX=/usr/bin/g++-15
export CUDAHOSTCXX=/usr/bin/g++-15

# ── Force a fresh CMake configuration ────────────────────────────────────────
export CMAKE_FRESH=1

echo "Environment variables set for PyTorch build (CUDA 13.3, arch 8.6, gcc-15)."
echo "Run: USE_NINJA=1 python setup.py install"
