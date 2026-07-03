#!/usr/bin/env bash
# 03 — Install cuDNN 9.22 (for CUDA 13) into the CUDA 13.3 tree.
# See docs/04-install-cudnn.md
set -euo pipefail

CUDNN_ARCHIVE="cudnn-linux-x86_64-9.22.0.52_cuda13-archive"
CUDNN_TAR="${CUDNN_ARCHIVE}.tar.xz"
CUDNN_URL="https://developer.download.nvidia.com/compute/cudnn/redist/cudnn/linux-x86_64/${CUDNN_TAR}"
CUDA_DIR="/usr/local/cuda-13.3"

echo ">> Downloading cuDNN 9.22 (CUDA 13 build)..."
wget -c --retry-connrefused --tries=0 --timeout=60 "$CUDNN_URL"

echo ">> Extracting..."
tar -xf "$CUDNN_TAR"

echo ">> Copying headers and libraries into ${CUDA_DIR}..."
sudo cp -r "${CUDNN_ARCHIVE}/include/"* "${CUDA_DIR}/include/"
sudo cp -r "${CUDNN_ARCHIVE}/lib/"*     "${CUDA_DIR}/lib64/"
sudo ldconfig

echo ">> Verifying..."
grep -H '#define CUDNN_MAJOR'      "${CUDA_DIR}/include/cudnn_version.h" || true
grep -H '#define CUDNN_MINOR'      "${CUDA_DIR}/include/cudnn_version.h" || true
grep -H '#define CUDNN_PATCHLEVEL' "${CUDA_DIR}/include/cudnn_version.h" || true
ldconfig -p | grep cudnn || echo "!! cudnn not yet visible to loader"

echo ">> Done. Next: ./scripts/04-pyenv-setup.sh"
