# Building PyTorch from Source with CUDA 13.3 + cuDNN 9.22 on Arch Linux (Artix) (RTX 3050)

A battle-tested, step-by-step manual for compiling **PyTorch 2.12.0** from source
against **CUDA 13.3** and **cuDNN 9.22** on **Arch Linux** (and Artix / other
derivatives), targeting an **NVIDIA RTX 3050** (compute capability `8.6`).

This repo exists because the "happy path" does not work on a bleeding-edge Arch
system. The stock Arch `cuda` package (13.2 at the time of writing) triggers a
`double free detected in tcache 2` crash even on a trivial `nvcc`-compiled C
program, and `glibc 2.43` cannot be downgraded without breaking the whole
system. The route that actually works is documented here end-to-end.

> ⚠️ **Read this first.** The exact version numbers below (driver `610.43.02`,
> CUDA `13.3.0`, cuDNN `9.22.0.52`, glibc `2.43`, gcc `15`, PyTorch `v2.12.0`)
> are the combination that worked on one specific machine at one point in time.
> Arch moves fast. Always re-check current version compatibility before you
> start — see [`docs/01-prerequisites-and-compatibility.md`](docs/01-prerequisites-and-compatibility.md).

---

## TL;DR

```bash
# 1. System build dependencies
./scripts/00-system-deps.sh

# 2. NVIDIA open beta driver (fixes glibc 2.43 incompatibility)
./scripts/01-beta-drivers.sh

# 3. CUDA 13.3 via the official runfile (NOT the Arch package)
./scripts/02-install-cuda-13.3.sh

# 4. cuDNN 9.22 (manual copy into the CUDA tree)
./scripts/03-install-cudnn.sh

# 5. Python 3.12.3 via pyenv + a clean virtualenv
./scripts/04-pyenv-setup.sh

# 6. Load the build environment and compile PyTorch 2.12.0
source ./scripts/exports.sh
./scripts/05-build-pytorch.sh

# 7. Verify
./scripts/test-pytorch.sh
```

Each step is explained in detail in [`docs/`](docs/). **Do not blindly run the
scripts** — several steps involve downloading multi-GB installers, replacing your
GPU driver, and a compile that can take an hour and eat all your RAM. Read the
matching doc page for each script first.

---

## Target system

| Component | Value |
|---|---|
| OS | Arch Linux / Artix (rolling) |
| GPU | NVIDIA RTX 3050 (Ampere, compute capability **8.6**) |
| Driver | `nvidia-open-beta` **610.43.02** |
| CUDA Toolkit | **13.3.0** (runfile install to `/usr/local/cuda-13.3`) |
| cuDNN | **9.22.0.52** for CUDA 13 |
| glibc | **2.43** |
| Host compiler | **gcc-15 / g++-15** |
| Python | **3.12.3** (via pyenv) |
| PyTorch | **v2.12.0** (built from source) |

---

## Why build from source at all?

For this exact CUDA 13.3 + RTX 3050 + Arch stack there is no matching prebuilt
PyTorch wheel. Official wheels lag behind the newest CUDA toolkits, and mixing a
prebuilt wheel's bundled CUDA with a hand-installed system CUDA is a common
source of subtle runtime crashes. Building from source guarantees PyTorch links
against *your* toolkit, *your* cuDNN, and is compiled with a host compiler CUDA
13.3 actually accepts.

---

## Repository layout

```
.
├── README.md                     ← you are here
├── docs/
│   ├── 00-overview.md            The full story: what broke and why
│   ├── 01-prerequisites-and-compatibility.md
│   ├── 02-nvidia-beta-drivers.md
│   ├── 03-install-cuda-13.3.md
│   ├── 04-install-cudnn.md
│   ├── 05-pyenv-python-setup.md
│   ├── 06-build-pytorch.md
│   ├── 07-verification.md
│   ├── 08-troubleshooting.md
│   └── 09-environment-variables.md
├── scripts/
│   ├── 00-system-deps.sh
│   ├── 01-beta-drivers.sh
│   ├── 02-install-cuda-13.3.sh
│   ├── 03-install-cudnn.sh
│   ├── 04-pyenv-setup.sh
│   ├── 05-build-pytorch.sh
│   ├── exports.sh                Source this before building
│   ├── test-cuda.sh             Standalone nvcc smoke test
│   └── test-pytorch.sh          PyTorch/CUDA/cuDNN verification
├── test/
│   └── test.cu                   Minimal CUDA "does the GPU exist" program
├── .gitignore
└── LICENSE
```

---

## Recommended reading order

1. [Overview — what broke and why](docs/00-overview.md)
2. [Prerequisites & compatibility](docs/01-prerequisites-and-compatibility.md)
3. [NVIDIA beta drivers](docs/02-nvidia-beta-drivers.md)
4. [Install CUDA 13.3](docs/03-install-cuda-13.3.md)
5. [Install cuDNN 9.22](docs/04-install-cudnn.md)
6. [pyenv & Python setup](docs/05-pyenv-python-setup.md)
7. [Build PyTorch 2.12.0](docs/06-build-pytorch.md)
8. [Verification](docs/07-verification.md)
9. [Troubleshooting](docs/08-troubleshooting.md)
10. [Environment variables explained](docs/09-environment-variables.md)

---

## Adapting this for a different GPU

The only GPU-specific knob is the compute capability. This guide uses `8.6` for
the RTX 3050. If your card differs, change `TORCH_CUDA_ARCH_LIST` in
[`scripts/exports.sh`](scripts/exports.sh):

| GPU family | Example cards | `TORCH_CUDA_ARCH_LIST` |
|---|---|---|
| Ampere | RTX 3050 / 3060 / 3090 | `8.6` |
| Ada Lovelace | RTX 4070 / 4090 | `8.9` |
| Hopper | H100 | `9.0` |
| Blackwell | RTX 5090 | `12.0` |

Look up your card's compute capability at
<https://developer.nvidia.com/cuda-gpus> before changing this.

---

## Disclaimer

This is a community field-guide, not official NVIDIA or PyTorch documentation.
Replacing GPU drivers and installing CUDA via runfile carries real risk of
leaving your system without working graphics. Have a way to reach a TTY / recover
before you begin. Nothing here is guaranteed to work on a future Arch snapshot.
