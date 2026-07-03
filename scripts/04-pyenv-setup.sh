#!/usr/bin/env bash
# 04 — Create an isolated Python 3.12.3 env for the PyTorch build.
# See docs/05-pyenv-python-setup.md
#
# NOTE: pyenv activation is a shell function, so this script installs the
# interpreter and virtualenv, then tells you to activate in YOUR shell.
set -euo pipefail

PY_VERSION="3.12.3"
VENV_NAME="cuda133"     # use this SAME name to create and activate

command -v pyenv >/dev/null || {
    echo "!! pyenv not found. Install it first (e.g. 'yay -S pyenv pyenv-virtualenv')"
    echo "   and add the init lines to your shell rc. See docs/05-pyenv-python-setup.md"
    exit 1
}

echo ">> Installing Python ${PY_VERSION} (skips if already present)..."
pyenv install -s "$PY_VERSION"

echo ">> Creating virtualenv '${VENV_NAME}'..."
pyenv virtualenv "$PY_VERSION" "$VENV_NAME" || echo "   (virtualenv may already exist)"

cat <<EOF

>> Now activate it in your current shell and upgrade packaging tools:

    pyenv activate ${VENV_NAME}
    pip install --upgrade pip setuptools wheel

>> Then continue with:  source ./scripts/exports.sh  &&  ./scripts/05-build-pytorch.sh
EOF
