#!/usr/bin/env bash
# 01 — Swap the stock nvidia-open stack for nvidia-open-beta (610.43.02).
# This is the ROOT-CAUSE fix for the glibc 2.43 incompatibility.
#
# ⚠️  This removes your working GPU driver and installs a beta from the AUR.
#     Have a way to reach a TTY (Ctrl+Alt+F3) before running. Reboot after.
#     See docs/02-nvidia-beta-drivers.md
set -euo pipefail

read -r -p "This will remove nvidia-open and install the beta driver. Continue? [y/N] " ans
[[ "${ans,,}" == "y" ]] || { echo "Aborted."; exit 1; }

echo ">> Removing stock open driver stack..."
sudo pacman -Rns nvidia-open nvidia-settings nvidia-utils

echo ">> Installing beta driver stack from the AUR (yay)..."
# If yay reports a package in both repo and AUR, disambiguate with aur/<pkg>:
#   yay -S aur/nvidia-utils-beta
yay -S nvidia-open-beta nvidia-settings-beta nvidia-utils-beta

echo
echo ">> Installed. REBOOT now, then verify with:  nvidia-smi"
echo ">> Expect driver 610.43.02 and your RTX 3050 listed."
echo ">> Do NOT continue to CUDA until nvidia-smi works."
