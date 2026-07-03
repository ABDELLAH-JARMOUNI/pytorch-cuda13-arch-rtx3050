#!/usr/bin/env bash
# Standalone CUDA smoke test: compiles test/test.cu with gcc-15 as host compiler
# and runs it. Expected output: "GPU count: 1".
# If you see "double free detected in tcache 2", your driver/CUDA pairing is
# still broken — see docs/08-troubleshooting.md
set -euo pipefail

NVCC="${CUDA_HOME:-/usr/local/cuda-13.3}/bin/nvcc"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${SCRIPT_DIR}/../test/test.cu"
OUT="/tmp/cuda_smoke_test"

echo ">> nvcc version:"
"$NVCC" --version

echo ">> Compiling ${SRC} with gcc-15 host compiler..."
"$NVCC" --compiler-bindir /usr/bin/gcc-15 "$SRC" -o "$OUT"

echo ">> Running..."
"$OUT"
echo ">> If you saw 'GPU count: 1', the toolkit + driver are healthy."
