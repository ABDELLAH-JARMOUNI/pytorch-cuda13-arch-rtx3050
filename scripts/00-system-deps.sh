#!/usr/bin/env bash
# 00 — System build dependencies for building PyTorch from source on Arch.
# Review before running. See docs/01-prerequisites-and-compatibility.md
set -euo pipefail

echo ">> Updating package database and system..."
sudo pacman -Syu

echo ">> Installing core development tools..."
sudo pacman -S --needed base-devel git cmake ninja python-pip

echo ">> Installing BLAS/LAPACK (used by PyTorch)..."
sudo pacman -S --needed openblas

echo ">> Installing runtime/dev libraries needed at compile time..."
sudo pacman -S --needed \
    gcc-fortran \
    libomp \
    libxnnpack \
    libjpeg-turbo \
    libpng \
    libprotobuf \
    protobuf \
    python-setuptools \
    python-wheel \
    python-pyzstd \
    python-typing-extensions

echo ">> Done. Next: ./scripts/01-beta-drivers.sh"
