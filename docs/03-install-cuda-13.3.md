# 03 — Install CUDA 13.3 (via the official runfile)

**Do not use the Arch `cuda` package for this.** At the time of writing it ships
CUDA 13.2, which triggers the `double free` bug. Instead, install CUDA **13.3**
straight from NVIDIA's runfile into a versioned directory, leaving your package
manager out of it.

## 1. Download the runfile

```bash
wget -c --retry-connrefused --tries=0 --timeout=60 \
  https://developer.download.nvidia.com/compute/cuda/13.3.0/local_installers/cuda_13.3.0_610.43.02_linux.run
```

Notes on the flags:
- `-c` resume a partial download.
- `--retry-connrefused --tries=0` keep retrying forever on flaky connections.
- The file is several GB. The `610.43.02` in the name matches the driver.

> Always grab the current URL from NVIDIA's
> [CUDA Toolkit archive](https://developer.nvidia.com/cuda-toolkit-archive) —
> hardcoded links rot.

## 2. Work around the libxml2 SONAME on Arch

The installer looks for `libxml2.so.2`, but current Arch ships `libxml2.so`.
Create a compatibility symlink so the installer's dependency check passes:

```bash
sudo ln -s /usr/lib/libxml2.so /usr/lib/libxml2.so.2
```

If the symlink already exists you'll get "File exists" — that's fine, move on.

## 3. Run the installer (toolkit only, silent)

```bash
sudo sh cuda_13.3.0_610.43.02_linux.run \
  --toolkit --silent \
  --installpath=/usr/local/cuda-13.3 \
  --override
```

What the flags mean:
- `--toolkit` install **only** the toolkit — **not** the bundled driver (you
  already installed the beta driver in step 02; do not let the runfile replace
  it).
- `--silent` no interactive prompts.
- `--installpath=/usr/local/cuda-13.3` version-pinned location, so multiple CUDA
  versions can coexist.
- `--override` proceed despite the installer's checks (e.g. an unsupported
  compiler warning, or a detected existing CUDA). Use deliberately.

## 4. Make `/usr/local/cuda` point at 13.3

The convention the rest of this guide relies on is a stable `/usr/local/cuda`
symlink that you re-point at whichever version is active:

```bash
sudo ln -sfn /usr/local/cuda-13.3 /usr/local/cuda
```

`-sfn`: symbolic, force-overwrite, and treat an existing symlink as a file (so it
gets replaced rather than nested inside).

## 5. Register the library path with the dynamic linker

So the runtime can find `libcudart.so.13` and friends system-wide:

```bash
sudo bash -c 'echo "/usr/local/cuda-13.3/lib64" > /etc/ld.so.conf.d/cuda.conf'
sudo ldconfig

# verify the loader now knows about the CUDA runtime
ldconfig -p | grep cudart   # should show a path under /usr/local/cuda-13.3/lib64
```

## 6. Smoke-test the toolkit

Confirm `nvcc` reports 13.3:

```bash
/usr/local/cuda-13.3/bin/nvcc --version
```

Then compile and run the minimal CUDA program in [`test/test.cu`](../test/test.cu),
telling nvcc to use gcc-15 as the host compiler:

```bash
/usr/local/cuda-13.3/bin/nvcc --compiler-bindir /usr/bin/gcc-15 test/test.cu -o /tmp/test
/tmp/test
```

Expected output:

```
GPU count: 1
```

If you instead get `free(): double free detected in tcache 2`, your CUDA/driver
pairing is still wrong — **stop and fix it here** before touching PyTorch. See
[troubleshooting](08-troubleshooting.md). The helper
[`scripts/test-cuda.sh`](../scripts/test-cuda.sh) automates this smoke test.

The whole sequence is captured in
[`scripts/02-install-cuda-13.3.sh`](../scripts/02-install-cuda-13.3.sh).

Next: [Install cuDNN 9.22](04-install-cudnn.md).
