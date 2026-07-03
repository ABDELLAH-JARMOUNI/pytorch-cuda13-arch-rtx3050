# 08 — Troubleshooting

The specific failures hit while getting this stack working, and how each was
diagnosed and fixed.

---

## `free(): double free detected in tcache 2`

**Symptom.** *Any* CUDA program — including a trivial one that only calls
`cudaGetDeviceCount()` — compiles with `nvcc` but crashes at runtime with a
double-free.

**How to isolate it.** Strip everything else away. Compile and run the minimal
reproducer:

```bash
cat > /tmp/test.cu << 'EOF'
#include <stdio.h>
int main() {
    int count;
    cudaGetDeviceCount(&count);
    printf("GPU count: %d\n", count);
    return 0;
}
EOF
nvcc /tmp/test.cu -o /tmp/test_cuda && /tmp/test_cuda
```

If *this* crashes, the problem is **not** PyTorch and **not** gcc — a bare C
program with no PyTorch anywhere fails identically. That narrows it to the CUDA
toolkit / driver / libc layer.

**Root cause (this system).** Two contributing factors were found:

1. The stock **CUDA 13.2** toolkit was itself broken on this machine.
2. Underneath that, the **`nvidia-open` kernel module was incompatible with
   glibc 2.43**.

**Fix.** Do **not** downgrade glibc (it breaks the system). Instead:

- Upgrade the driver to **`nvidia-open-beta` 610.43.02**
  ([step 02](02-nvidia-beta-drivers.md)).
- Install **CUDA 13.3** via runfile, bypassing the broken 13.2 Arch package
  ([step 03](03-install-cuda-13.3.md)).

Re-run the reproducer; it should now print `GPU count: 1`.

---

## The tempting-but-wrong path: downgrading CUDA to 12.8

Before the driver fix was understood, the plan was to fall back to CUDA **12.8**.
That path is documented here mainly so you recognize it and know its pitfalls.

Downgrading needs an older compiler too (CUDA 12.8 wants **gcc-13**):

```bash
yay -S gcc13 gcc13-libs gcc13-fortran
sudo downgrade cuda        # then choose 12.8.0
```

`downgrade` may hit keyring problems on Artix-based systems:

```bash
sudo pacman -Sy artix-keyring
sudo pacman-key --init
sudo pacman-key --populate artix

# if a specific key ID is reported as missing, import it manually:
sudo pacman-key --recv-keys 001CF4810BE8D911
sudo pacman-key --lsign-key 001CF4810BE8D911
```

**Why this was abandoned.** The real fix was the driver, not the toolkit. Moving
the driver forward let the build go *forward* to CUDA 13.3 rather than backward to
12.8 — simpler, and it keeps you on a current toolkit. Downgrading is only worth
it if you cannot get a compatible driver at all.

> **Driver reassurance.** You do **not** need to touch the driver when changing
> toolkit versions downward. NVIDIA drivers are backward compatible: a newer
> driver always supports older CUDA toolkits. Driver 595 supports CUDA 12.8
> fine; the only broken pairing is a driver *older* than the toolkit requires.

---

## CUDA runfile installer fails on Arch

**Symptom.** The `.run` installer aborts complaining about a missing
`libxml2.so.2`.

**Fix.** Current Arch ships `libxml2.so`; create the SONAME the installer wants:

```bash
sudo ln -s /usr/lib/libxml2.so /usr/lib/libxml2.so.2
```

Also pass `--override` to the installer to get past compiler/version warnings you
have consciously decided to ignore.

---

## `error while loading shared libraries: libcudart.so.13`

**Cause.** The dynamic linker can't find the CUDA runtime.

**Fix.** Register the CUDA lib dir and refresh the loader cache:

```bash
sudo bash -c 'echo "/usr/local/cuda-13.3/lib64" > /etc/ld.so.conf.d/cuda.conf'
sudo ldconfig
ldconfig -p | grep cudart   # confirm it resolves under /usr/local/cuda-13.3/lib64
```

And make sure your shell has `LD_LIBRARY_PATH` set (see
[exports.sh](../scripts/exports.sh) and
[09-environment-variables](09-environment-variables.md)).

---

## `nvcc` rejects the host compiler

**Symptom.** nvcc errors about an unsupported host compiler version.

**Cause.** CUDA 13.3 needs a recent gcc. Your default `gcc` may be too new *or*
too old for what nvcc expects, or nvcc is picking the wrong one.

**Fix.** Pin gcc-15 explicitly:

```bash
nvcc --compiler-bindir /usr/bin/gcc-15 test/test.cu -o /tmp/test
```

For the PyTorch build, `exports.sh` already sets `CC`, `CXX`, and `CUDAHOSTCXX`
to the gcc-15 toolchain so nvcc and the host build agree.

---

## The build hangs / freezes the whole machine

**Cause.** Too many parallel compile jobs exhausting RAM. Using `nproc` (all
cores) was enough to fill memory on this box.

**Fix.** Cap parallelism in `exports.sh`:

```bash
export MAX_JOBS=6     # lower still if you continue to OOM
```

Do not also pass `-- -j<N>` to `setup.py`; `MAX_JOBS` already controls it.

---

## Wrong PyTorch version got built (e.g. 2.13 dev)

**Cause.** Building from `main` instead of a release tag.

**Fix.** Check out the tag before building, and re-sync submodules:

```bash
cd ~/src/pytorch
git fetch --tags
git checkout v2.12.0
git submodule sync
git submodule update --init --recursive
cat version.txt        # confirm 2.12.0
```

---

## "no such virtualenv" from pyenv

**Cause.** Creating one venv name and activating a different one (e.g. created
`cuda133`, activated `cuda3`).

**Fix.** Use one consistent name for both `pyenv virtualenv` and
`pyenv activate`. This guide standardizes on `cuda133`.

---

If your problem isn't here, re-run the compatibility checks in
[01-prerequisites-and-compatibility](01-prerequisites-and-compatibility.md) —
most remaining issues are a version mismatch somewhere in the chain.
