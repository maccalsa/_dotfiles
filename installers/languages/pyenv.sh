#!/usr/bin/env bash

set -euo pipefail

DEFAULT_PYTHON_VERSION="${DEFAULT_PYTHON_VERSION:-3.14.4}"

read -r -p "Enter the version of python you want to install (default: $DEFAULT_PYTHON_VERSION): " PYTHON_VERSION
if [ -z "$PYTHON_VERSION" ]; then
  PYTHON_VERSION=$DEFAULT_PYTHON_VERSION
fi

# Install dependencies (needed for building Python)
sudo apt install -y make build-essential libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
  libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

if [ -d "$HOME/.pyenv/.git" ]; then
  git -C "$HOME/.pyenv" pull --ff-only
else
  curl -fsSL https://pyenv.run | bash
fi

# Add to your shell
if ! grep -q 'PYENV_ROOT' "$HOME/.zshrc" 2>/dev/null; then
  cat >> "$HOME/.zshrc" <<'EOF'
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
EOF
fi

# Reload shell config
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Install Python.
echo "Installing Python, this may take sometime"
pyenv install --skip-existing "$PYTHON_VERSION"
pyenv global "$PYTHON_VERSION"

# Make sure pip is up to date
python -m ensurepip --upgrade
python -m pip install --upgrade pip

# ✅ Install pipx
python -m pip install --user pipx
python -m pipx ensurepath

# Reload path (if needed in current shell)
export PATH="$HOME/.local/bin:$PATH"

# ✅ Use pipx to install virtualenv & poetry
pipx install virtualenv || pipx upgrade virtualenv
pipx install poetry || pipx upgrade poetry

# 🧪 Test
python --version
pipx list
poetry --version
virtualenv --version