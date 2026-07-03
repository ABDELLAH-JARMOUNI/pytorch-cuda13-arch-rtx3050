# 01 — Prerequisites & compatibility

> The single most important habit in this whole guide:
> **before installing anything, check that your gcc, glibc, NVIDIA driver, CUDA,
> and cuDNN versions are mutually compatible.** Most failures downstream are a
> version mismatch that a two-minute check would have caught.

## Check what you have

```bash
# Kernel & distro
uname -r
cat /etc/os-release | head -n1

# glibc version (this is the one you generally CANNOT downgrade)
ldd --version | head -n1

# Current gcc (and any side-by-side versions)
gcc --version
pacman -Qs '^gcc'

# NVIDIA driver + GPU
nvidia-smi

# Any existing CUDA
ls -d /opt/cuda /usr/local/cuda* 2>/dev/null
nvcc --version 2>/dev/null || echo "no nvcc on PATH yet"
```

## The compatibility chain

Each link constrains the next:

```
GPU compute capability ─┐
                        ├─► CUDA toolkit version ─► host gcc version
NVIDIA driver version ──┘                        └─► cuDNN version
                          glibc ─► NVIDIA kernel module (open vs proprietary)
```

### 1. GPU → compute capability

The RTX 3050 is **Ampere, compute capability 8.6**. This is fixed by your
hardware and becomes `TORCH_CUDA_ARCH_LIST="8.6"`. Look yours up at
<https://developer.nvidia.com/cuda-gpus>.

### 2. Driver ↔ CUDA toolkit

**Newer driver + older toolkit = fine.** NVIDIA drivers are backward compatible.

| Combination | Result |
|---|---|
| Driver 610 + CUDA 13.3 | ✅ works (this guide) |
| Driver 595 + CUDA 12.8 | ✅ works (driver newer than toolkit needs) |
| Driver 595 + CUDA 13.2 | ⚠️ "should" work but hit the double-free bug |
| Driver 525 + CUDA 13.2 | ❌ driver too old for the toolkit |

The takeaway from the earlier debugging: you almost never need to *downgrade* a
driver. You fix problems by moving the driver forward or the toolkit sideways.

### 3. glibc ↔ kernel module

This is the subtle one that caused the original crash. **glibc 2.43** was
incompatible with the stock **`nvidia-open`** kernel module, which surfaced as a
CUDA runtime `double free`. The fix was `nvidia-open-beta` (see
[step 02](02-nvidia-beta-drivers.md)). **Do not try to downgrade glibc** — it
breaks the system.

### 4. CUDA toolkit → host gcc

CUDA is picky about which gcc it will compile host code with. **CUDA 13.3 needs a
recent gcc; this build uses gcc-15.** If you ever go back to an older CUDA (e.g.
12.8), you must *also* install an older gcc (e.g. gcc-13) — that pairing is why
the aborted downgrade attempt installed `gcc13 gcc13-libs gcc13-fortran`.

Rule of thumb: match the compiler to the toolkit, not to whatever your system
`gcc` happens to be.

### 5. CUDA toolkit → cuDNN

cuDNN ships per CUDA major version. This guide uses **cuDNN 9.22.0.52 built for
CUDA 13**. Grab the "for CUDA 13" archive, not the CUDA 12 one.

## Version matrix used in this guide

| Layer | Pinned version | Why |
|---|---|---|
| glibc | 2.43 | System default; can't downgrade |
| NVIDIA driver | nvidia-open-beta 610.43.02 | Compatible with glibc 2.43 |
| CUDA toolkit | 13.3.0 | Avoids the 13.2 double-free bug |
| Host gcc | 15 | Required by CUDA 13.3 |
| cuDNN | 9.22.0.52 (cuda13) | Matches CUDA 13 |
| Python | 3.12.3 | Stable, well-supported by PyTorch |
| PyTorch | v2.12.0 | Supports CUDA 13.x from source |

> These are a known-good snapshot, **not** eternal truths. On a fresh Arch
> install months later, the current CUDA, cuDNN, and driver versions may differ.
> Re-run the checks above and adjust the version strings in the scripts.

## System build dependencies

Install the toolchain and libraries PyTorch needs at compile time:

```bash
./scripts/00-system-deps.sh
```

That script runs a `pacman -Syu` and installs `base-devel`, `git`, `cmake`,
`ninja`, `openblas`, and the various runtime/dev libraries PyTorch links against.
Review it before running — see [`scripts/00-system-deps.sh`](../scripts/00-system-deps.sh).

Next: [NVIDIA beta drivers](02-nvidia-beta-drivers.md).
