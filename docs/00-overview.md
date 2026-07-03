# 00 — Overview: what broke and why

This page is the story behind the whole repo. If you just want commands, skip to
[step 01](01-prerequisites-and-compatibility.md). But if you are debugging a
similar mess, the reasoning here will save you hours.

## The goal

Build PyTorch from source with GPU acceleration on a rolling-release Arch system
with an RTX 3050. Simple on paper. In practice, three separate landmines had to
be cleared.

## Landmine 1 — CUDA 13.2 is broken on this system

The stock Arch `cuda` package was version **13.2**. A *minimal* CUDA program —
one that only calls `cudaGetDeviceCount()` and prints the result — compiled fine
with `nvcc` but crashed at runtime:

```
free(): double free detected in tcache 2
```

This is important because it rules out PyTorch, gcc, and Arch packaging as the
cause. A plain C program with no PyTorch anywhere crashes the same way. The
conclusion: **CUDA 13.2 itself is broken on this machine.** See
[`test/test.cu`](../test/test.cu) for the exact reproducer and
[docs/08-troubleshooting.md](08-troubleshooting.md) for the full diagnosis.

## Landmine 2 — you cannot just downgrade

The obvious fix is "drop back to a known-good CUDA (12.8)." That path has its own
wall: the system's **glibc is 2.43**, and glibc cannot be safely downgraded on
Arch — doing so breaks essentially every dynamically linked binary, including the
tools you need to fix it. So downgrading CUDA to 12.8 (with gcc-13) is *possible*
in principle, but the deeper issue turned out to be elsewhere.

## Landmine 3 — the real root cause: nvidia-open + glibc 2.43

The actual root cause was an incompatibility between the **`nvidia-open` kernel
module** and **glibc 2.43**. The CUDA 13.2 crash was a symptom. The fix was not
to downgrade CUDA but to move the *driver* forward:

- Remove the stock `nvidia-open` (+ `nvidia-utils`, `nvidia-settings`).
- Install **`nvidia-open-beta` 610.43.02** from the AUR.

With a driver that plays nicely with glibc 2.43, the door opens to a *newer*
CUDA instead of an older one.

## The winning combination

Rather than fight backwards to 12.8, the build went forward to **CUDA 13.3**,
installed via NVIDIA's **official runfile** (bypassing the broken Arch package
entirely) into `/usr/local/cuda-13.3`. Then:

- **cuDNN 9.22** copied manually into the CUDA tree.
- **gcc-15** used as the host compiler, because CUDA 13.3 requires a recent gcc.
- **PyTorch v2.12.0** checked out and compiled from source against all of the
  above.

## Summary of fixes (the short version)

1. **Root cause:** `nvidia-open` kernel module + glibc 2.43 incompatibility.
2. **Fix:** upgrade to `nvidia-open-beta` **610.43.02**.
3. Install **CUDA 13.3** via runfile (bypassing the broken Arch package).
4. Install **cuDNN 9.22** manually.
5. Build **PyTorch 2.12.0** with **gcc-15** to satisfy CUDA 13.3.

## Mental model going forward

- **Driver is newer than the toolkit needs → fine.** NVIDIA drivers are
  backward compatible; a newer driver always supports older CUDA toolkits. You
  only worry about the driver when you push CUDA *beyond* what the driver
  supports.
- **Toolkit lives in `/usr/local/cuda-13.3`, symlinked as `/usr/local/cuda`.**
  Everything (PATH, LD_LIBRARY_PATH, cmake) points at that.
- **One host compiler for everything.** gcc-15 compiles the CUDA test, and
  gcc-15 (`CC`/`CXX`/`CUDAHOSTCXX`) builds PyTorch. No mixing.

Now continue to [prerequisites & compatibility](01-prerequisites-and-compatibility.md).
