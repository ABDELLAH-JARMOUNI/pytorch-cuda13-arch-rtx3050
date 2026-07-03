# 04 — Install cuDNN 9.22

Because the CUDA toolkit was installed by runfile (not by pacman), cuDNN also has
to be placed by hand. The approach: download the tarball for **CUDA 13**, unpack
it, and copy the headers and libraries straight into the CUDA 13.3 tree so they
sit alongside the toolkit.

## 1. Get the download

Browse to the cuDNN downloads page and pick the **Linux / x86_64 / Agnostic /
CUDA 13 / Full** tarball:

<https://developer.nvidia.com/cudnn-downloads?target_os=Linux&target_arch=x86_64&Distribution=Agnostic&cuda_version=13&Configuration=Full>

Then fetch it (version 9.22.0.52 for CUDA 13 in this guide):

```bash
wget -c --retry-connrefused --tries=0 --timeout=60 \
  https://developer.download.nvidia.com/compute/cudnn/redist/cudnn/linux-x86_64/cudnn-linux-x86_64-9.22.0.52_cuda13-archive.tar.xz
```

> The `_cuda13` suffix matters. Do not grab the `_cuda12` archive — it targets a
> different toolkit ABI.

## 2. Unpack

```bash
tar -xf cudnn-linux-x86_64-9.22.0.52_cuda13-archive.tar.xz
```

This produces a directory `cudnn-linux-x86_64-9.22.0.52_cuda13-archive/` with
`include/` and `lib/` subfolders.

## 3. Copy into the CUDA tree

```bash
sudo cp -r cudnn-linux-x86_64-9.22.0.52_cuda13-archive/include/* /usr/local/cuda-13.3/include/
sudo cp -r cudnn-linux-x86_64-9.22.0.52_cuda13-archive/lib/*     /usr/local/cuda-13.3/lib64/
sudo ldconfig
```

Placing cuDNN inside `/usr/local/cuda-13.3` means the `CUDA_HOME`-based paths you
already exported cover it too — PyTorch's build will find cuDNN automatically via
`USE_CUDNN=1`.

## 4. Verify the files landed

```bash
# header present?
ls -l /usr/local/cuda-13.3/include/cudnn_version.h

# read the version macros
grep '#define CUDNN_MAJOR'      /usr/local/cuda-13.3/include/cudnn_version.h
grep '#define CUDNN_MINOR'      /usr/local/cuda-13.3/include/cudnn_version.h
grep '#define CUDNN_PATCHLEVEL' /usr/local/cuda-13.3/include/cudnn_version.h

# libraries registered with the loader?
ldconfig -p | grep cudnn
```

You should see `CUDNN_MAJOR 9` and the `libcudnn` entries pointing under
`/usr/local/cuda-13.3/lib64`.

The full sequence is in
[`scripts/03-install-cudnn.sh`](../scripts/03-install-cudnn.sh).

Next: [pyenv & Python setup](05-pyenv-python-setup.md).
