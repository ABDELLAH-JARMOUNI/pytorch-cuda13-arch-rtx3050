#!/usr/bin/env bash
# 02 — Install CUDA 13.3 from NVIDIA's runfile (bypassing the broken Arch pkg).
# See docs/03-install-cuda-13.3.md
set -euo pipefail

CUDA_RUN="cuda_13.3.0_610.43.02_linux.run"
CUDA_URL="https://developer.download.nvidia.com/compute/cuda/13.3.0/local_installers/${CUDA_RUN}"
CUDA_DIR="/usr/local/cuda-13.3"

echo ">> Downloading CUDA 13.3 runfile (several GB)..."
wget -c --retry-connrefused --tries=0 --timeout=60 "$CUDA_URL"

echo ">> Ensuring libxml2.so.2 SONAME exists for the installer..."
if [[ ! -e /usr/lib/libxml2.so.2 ]]; then
    sudo ln -s /usr/lib/libxml2.so /usr/lib/libxml2.so.2
else
    echo "   libxml2.so.2 already present, skipping."
fi

echo ">> Running installer (toolkit only, silent)..."
# --toolkit : install ONLY the toolkit, not the bundled driver (keep our beta driver)
# --override: proceed past compiler/existing-install warnings
sudo sh "$CUDA_RUN" --toolkit --silent --installpath="$CUDA_DIR" --override

echo ">> Pointing /usr/local/cuda at 13.3..."
sudo ln -sfn "$CUDA_DIR" /usr/local/cuda

echo ">> Registering CUDA libs with the dynamic linker..."
sudo bash -c "echo '${CUDA_DIR}/lib64' > /etc/ld.so.conf.d/cuda.conf"
sudo ldconfig

echo ">> Verifying..."
"${CUDA_DIR}/bin/nvcc" --version
ldconfig -p | grep cudart || { echo "!! cudart not found by loader"; exit 1; }

echo ">> Done. Smoke-test the toolkit with:  ./scripts/test-cuda.sh"
