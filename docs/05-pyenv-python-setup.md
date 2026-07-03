# 05 — pyenv & Python setup

Build PyTorch inside an **isolated Python 3.12.3** environment created with
`pyenv`. This keeps the build off your system Python and makes it trivial to
throw away and start over — which you *will* do at least once.

## Why pyenv + a virtualenv

- **Reproducible interpreter.** `pyenv` builds a specific CPython (3.12.3) from
  source, independent of whatever Arch's `python` package is today.
- **Clean slate.** If a build goes sideways, deleting the virtualenv and making a
  fresh one is the fastest recovery — far cleaner than un-picking a half-built
  PyTorch from a shared environment.
- **No `sudo pip`.** Everything installs into the venv, never system-wide.

## 1. Ensure pyenv is installed

If you don't already have it:

```bash
# via the AUR
yay -S pyenv pyenv-virtualenv

# then add to your shell rc (e.g. ~/.bashrc), if not already present:
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
```

Open a new shell (or `source ~/.bashrc`) so `pyenv` is on your PATH.

## 2. Install Python 3.12.3

```bash
pyenv install 3.12.3
```

## 3. Create and activate a dedicated virtualenv

```bash
pyenv virtualenv 3.12.3 cuda133
pyenv activate cuda133
```

> **Naming consistency matters.** Create and activate the *same* name. An earlier
> draft of these notes created `cuda133` but tried to activate `cuda3` — that
> mismatch just fails with "no such virtualenv". Pick one name and use it
> everywhere. This guide uses **`cuda133`**.

## 4. Update the packaging tools

```bash
pip install --upgrade pip setuptools wheel
```

That's it for Python setup. The environment is empty and ready for PyTorch's
build requirements, which get installed in the next step.

Automated in [`scripts/04-pyenv-setup.sh`](../scripts/04-pyenv-setup.sh).

Next: [Build PyTorch 2.12.0](06-build-pytorch.md).
