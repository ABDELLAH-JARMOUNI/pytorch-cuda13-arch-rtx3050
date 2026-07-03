# 09 — Environment variables explained

Every variable set in [`scripts/exports.sh`](../scripts/exports.sh), what it does,
and why it's set the way it is. Source that file in the shell you build from:

```bash
source ./scripts/exports.sh
```

---

## CUDA location & path variables

### `CUDA_HOME`

```bash
export CUDA_HOME=/usr/local/cuda-13.3
```

The root of the CUDA install. Build tools (cmake when configuring PyTorch) and
applications look here to find the toolkit; it's the reference point every other
CUDA path is derived from.

> This guide points `CUDA_HOME` **directly** at `/usr/local/cuda-13.3`. You can
> instead point it at the `/usr/local/cuda` symlink if you prefer a version you
> can flip in one place — both work, as long as the symlink resolves to 13.3.

### `PATH`

```bash
export PATH=$CUDA_HOME/bin:$PATH
```

Tells the shell where to find executables. Prepending `$CUDA_HOME/bin` ensures
that when you run `nvcc` or `cuda-gdb`, you get the **13.3** binaries rather than
some other CUDA on the system or an older default. Order matters — front of the
list wins.

### `LD_LIBRARY_PATH`

```bash
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
```

Tells the dynamic linker where to find shared libraries (`.so` files) at runtime,
like `libcudart.so` and `libcublas.so`. Without it you get
`error while loading shared libraries: libcudart.so.13: cannot open shared object
file`. Keeping `$LD_LIBRARY_PATH` on the end preserves access to other system
libraries.

> This is belt-and-suspenders with the `ldconfig` step in
> [step 03](03-install-cuda-13.3.md). `ldconfig` handles system-wide resolution;
> `LD_LIBRARY_PATH` covers the current shell. Setting both is fine.

### `CUDA_TOOLKIT_ROOT_DIR` / `CMAKE_CUDA_COMPILER`

```bash
export CUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda-13.3
export CMAKE_CUDA_COMPILER=/usr/local/cuda-13.3/bin/nvcc
```

Explicitly hand cmake the toolkit root and the exact `nvcc` to use, so its CUDA
autodetection can't wander off to a different install.

---

## Feature toggles

### `USE_CUDA` / `USE_CUDNN`

```bash
export USE_CUDA=1
export USE_CUDNN=1
```

Turn on GPU support and cuDNN-accelerated kernels in the PyTorch build. Without
these you'd get a CPU-only PyTorch.

### `USE_FLASH_ATTENTION`

```bash
export USE_FLASH_ATTENTION=1
```

Builds fast fused-attention kernels — worth it for transformer workloads.

### `BUILD_TEST` / `USE_DISTRIBUTED`

```bash
export BUILD_TEST=0        # skip building C++ test binaries → faster build
export USE_DISTRIBUTED=0   # no multi-node/multi-GPU comms → not needed on one GPU
```

Both trimmed to speed up a single-GPU build. Set `USE_DISTRIBUTED=1` if you
actually need `torch.distributed`.

---

## GPU architecture

### `TORCH_CUDA_ARCH_LIST`

```bash
export TORCH_CUDA_ARCH_LIST="8.6"
```

Compute capability of the RTX 3050 (Ampere). Restricting to `8.6` compiles
kernels for *only* your GPU — smaller binaries, shorter builds. Change this for a
different card (Ada = `8.9`, Hopper = `9.0`, etc.). Look yours up at
<https://developer.nvidia.com/cuda-gpus>.

---

## Build performance

### `MAX_JOBS`

```bash
# export MAX_JOBS=$(nproc)   # all cores — can OOM and hang the system
export MAX_JOBS=6            # stable ceiling on this machine
```

Number of parallel compile jobs. `nproc` (all cores) exhausted RAM and froze the
system during the heaviest files; `6` was the reliable value. Lower it if you
still OOM. This replaces any need to pass `-- -j6` to `setup.py`.

### `REL_WITH_DEB_INFO`

```bash
export REL_WITH_DEB_INFO=1
```

Optimized build **with** debug symbols — near release performance while keeping
usable stack traces if something crashes.

### `CMAKE_FRESH`

```bash
export CMAKE_FRESH=1
```

Forces cmake to reconfigure from scratch rather than reuse a stale cache — avoids
"it's using my old settings" confusion after you change flags.

---

## Compiler selection

### `CFLAGS`

```bash
export CFLAGS="-O3 -march=native"
```

Aggressive optimization tuned for *this* CPU. `-march=native` means the resulting
binaries may not run on a different CPU — fine for a personal build box.

### `CC` / `CXX` / `CUDAHOSTCXX`

```bash
export CC=/usr/bin/gcc-15
export CXX=/usr/bin/g++-15
export CUDAHOSTCXX=/usr/bin/g++-15
```

Pin the C, C++, and **CUDA host** compilers all to the gcc-15 toolchain. CUDA
13.3 requires a recent gcc, and `CUDAHOSTCXX` guarantees nvcc uses the *same*
compiler as the rest of the build — mismatched host compilers are a classic
source of link errors. Keeping all three aligned is the whole point.

---

## Quick reference

| Variable | Value | Role |
|---|---|---|
| `CUDA_HOME` | `/usr/local/cuda-13.3` | Toolkit root |
| `PATH` | `$CUDA_HOME/bin:$PATH` | Find `nvcc` etc. |
| `LD_LIBRARY_PATH` | `$CUDA_HOME/lib64:...` | Find `.so` at runtime |
| `CUDA_TOOLKIT_ROOT_DIR` | `/usr/local/cuda-13.3` | cmake CUDA root |
| `CMAKE_CUDA_COMPILER` | `.../bin/nvcc` | Exact nvcc for cmake |
| `USE_CUDA` / `USE_CUDNN` | `1` | Enable GPU + cuDNN |
| `USE_FLASH_ATTENTION` | `1` | Fused attention kernels |
| `BUILD_TEST` / `USE_DISTRIBUTED` | `0` | Trim the build |
| `TORCH_CUDA_ARCH_LIST` | `8.6` | RTX 3050 arch |
| `MAX_JOBS` | `6` | Parallelism (avoid OOM) |
| `REL_WITH_DEB_INFO` | `1` | Optimized + symbols |
| `CMAKE_FRESH` | `1` | Fresh cmake config |
| `CFLAGS` | `-O3 -march=native` | CPU-tuned optimization |
| `CC`/`CXX`/`CUDAHOSTCXX` | gcc-15 / g++-15 | Consistent host compiler |
