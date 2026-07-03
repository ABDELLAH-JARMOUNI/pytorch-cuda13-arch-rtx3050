#!/usr/bin/env bash
# 05 — Clone, pin to v2.12.0, and build PyTorch from source.
# Run INSIDE your activated 'cuda133' pyenv virtualenv, AFTER: source ./scripts/exports.sh
# See docs/06-build-pytorch.md
set -euo pipefail

PYTORCH_TAG="v2.12.0"
SRC_DIR="$HOME/src/pytorch"

# Sanity: make sure the build env was sourced.
: "${CUDA_HOME:?Run 'source ./scripts/exports.sh' first}"
if [[ "${TORCH_CUDA_ARCH_LIST:-}" != "8.6" ]]; then
    echo "!! TORCH_CUDA_ARCH_LIST is not 8.6 — did you source exports.sh?"
fi

if [[ ! -d "$SRC_DIR" ]]; then
    echo ">> Cloning PyTorch..."
    mkdir -p "$HOME/src"
    git clone --recursive https://github.com/pytorch/pytorch.git "$SRC_DIR"
fi

cd "$SRC_DIR"

echo ">> Checking out ${PYTORCH_TAG}..."
git fetch --tags
git checkout "$PYTORCH_TAG"
git submodule sync
git submodule update --init --recursive

echo ">> Version to be built:"
cat version.txt

echo ">> Installing Python build requirements..."
pip install -r requirements.txt

echo ">> Building (this takes a while; MAX_JOBS=${MAX_JOBS:-unset})..."
# No trailing '-- -j<N>' needed; MAX_JOBS controls parallelism.
USE_NINJA=1 python setup.py install

echo ">> Build complete. Verify with:  ./scripts/test-pytorch.sh"
