# 02 — NVIDIA beta drivers (the actual root-cause fix)

This is the step that fixes the underlying problem. Everything else is downstream
of getting a driver that is compatible with **glibc 2.43**.

## Why

The stock `nvidia-open` kernel module was incompatible with glibc 2.43. The
visible symptom was a CUDA runtime crash (`double free detected in tcache 2`)
even from a trivial program. Upgrading to the **open beta** driver
(`610.43.02`) resolves it and, as a bonus, is what CUDA 13.3's bundled runfile
expects.

> **`nvidia-open` vs `nvidia`:** `nvidia-open` is NVIDIA's open-source kernel
> module, recommended for Turing and newer (the RTX 3050 qualifies). Stick with
> the "open" line here — this whole fix is about the open module's beta build.

## ⚠️ Risk warning

You are removing your working GPU driver and installing a beta from the AUR. If
it goes wrong you can land at a black screen. Before you start:

- Know how to switch to a TTY (`Ctrl`+`Alt`+`F3`) and log in there.
- Ideally have a second machine / phone to read these docs from.
- Consider taking a `timeshift` / filesystem snapshot if you use one.

## Steps

### 1. Remove the current open driver stack

```bash
sudo pacman -Rns nvidia-open nvidia-settings nvidia-utils
```

`-Rns` also removes now-unneeded dependencies and saves config as `.pacsave`.

### 2. Install the beta stack from the AUR

Using an AUR helper (`yay` shown here):

```bash
yay -S nvidia-open-beta nvidia-settings-beta nvidia-utils-beta
```

If `yay` complains about a package existing in both the official repos and the
AUR, disambiguate explicitly:

```bash
yay -S aur/nvidia-utils-beta
yay -S nvidia-open-beta
```

The full script is [`scripts/01-beta-drivers.sh`](../scripts/01-beta-drivers.sh).

### 3. Reboot and verify

```bash
sudo reboot
```

After logging back in:

```bash
nvidia-smi
```

You should see your RTX 3050 listed and the driver version reported as
`610.43.02` (or whatever beta you installed). If `nvidia-smi` errors out, do not
proceed to CUDA — sort the driver out first (see
[troubleshooting](08-troubleshooting.md)).

## What you should NOT do

- **Don't downgrade glibc** to "match" the old driver. It breaks the system.
- **Don't downgrade the driver.** The problem is solved by going *forward*, not
  back. A newer driver supports older toolkits anyway.

Once `nvidia-smi` is happy, continue to [Install CUDA 13.3](03-install-cuda-13.3.md).
