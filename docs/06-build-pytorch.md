# 06 — Build PyTorch 2.12.0 from source

With driver, CUDA, cuDNN, and Python in place, compile PyTorch. Expect this to
take a long time and to be memory-hungry — plan for it.

> **Activate your venv first.** Everything below runs inside the `cuda133`
> pyenv virtualenv from [step 05](05-pyenv-python-setup.md):
> ```bash
> pyenv activate cuda133
> ```

## 1. Load the build environment

All the toggles and compiler choices live in one file. Source it in the shell you
will build from:

```bash
source ./scripts/exports.sh
```

This sets `CUDA_HOME`, points cmake at the right `nvcc`, enables CUDA + cuDNN,
sets `TORCH_CUDA_ARCH_LIST=8.6`, selects **gcc-15 / g++-15** as the host and CUDA
host compiler, and caps parallelism. Every variable is explained in
[docs/09-environment-variables.md](09-environment-variables.md). The full file is
[`scripts/exports.sh`](../scripts/exports.sh).

Two knobs worth knowing before you start:

- **`MAX_JOBS=6`.** Using all cores (`nproc`) can exhaust RAM on this machine and
  hang the system during the heaviest translation units. `6` was the stable
  ceiling. Lower it further if you still OOM; raise it cautiously if you have RAM
  to spare.
- **`TORCH_CUDA_ARCH_LIST="8.6"`.** Compiles kernels only for the RTX 3050,
  keeping build time and binary size down. Change this if your GPU differs.

## 2. Clone PyTorch

```bash
mkdir -p ~/src && cd ~/src
git clone --recursive https://github.com/pytorch/pytorch.git
cd pytorch
git submodule sync
git submodule update --init --recursive
```

## 3. Check out the target release

Pin to **v2.12.0** (checking out a tagged release avoids surprises from `main`):

```bash
git fetch --tags
git checkout v2.12.0
git submodule sync
git submodule update --init --recursive
```

Confirm the version you're about to build:

```bash
cat ~/src/pytorch/version.txt
```

> Building `main` instead of a tag will give you a newer, unpinned version (an
> earlier attempt yielded a `2.13` dev build that way). Tags are reproducible;
> `main` is not. Prefer the tag.

## 4. Install Python build requirements

```bash
pip install -r requirements.txt
```

## 5. Compile

From inside the activated venv and the PyTorch checkout:

```bash
USE_NINJA=1 python setup.py install
```

- `USE_NINJA=1` uses Ninja for a faster, better-parallelized build.
- **No trailing `-- -j6` needed** — parallelism comes from `MAX_JOBS=6` in
  `exports.sh`. Passing both is redundant.

This step is long. A good sign it's working: `cmake` configures cleanly (finds
CUDA 13.3, cuDNN 9.22, your RTX 3050 arch), then thousands of compile lines
stream past.

## Rebuilding cleanly

If you need to start the compile over (changed a flag, switched tag, or a build
wedged):

```bash
cd ~/src/pytorch
pip uninstall torch          # remove any previously installed build
rm -rf build/                # nuke the build tree
git checkout v2.12.0         # make sure you're on the intended tag
git submodule sync
git submodule update --init --recursive
pip install -r requirements.txt
USE_NINJA=1 python setup.py install
```

For a truly clean slate, create a **fresh pyenv virtualenv** rather than reusing
a polluted one (see [step 05](05-pyenv-python-setup.md)).

The end-to-end build is scripted in
[`scripts/05-build-pytorch.sh`](../scripts/05-build-pytorch.sh).

Next: [Verification](07-verification.md).
