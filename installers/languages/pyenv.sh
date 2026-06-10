#!/usr/bin/env bash

set -euo pipefail

ACTION="install"
PYTHON_VERSION=""
DEFAULT_PYTHON_VERSION="${DEFAULT_PYTHON_VERSION:-3.14.4}"

usage() {
  cat <<'USAGE'
Usage: pyenv.sh [install|upgrade] [options]

Actions:
  install  Install pyenv and the requested Python version (default)
  upgrade  Install a new Python version via pyenv and set it as global

Options:
  --version VERSION  Python version to install (e.g. 3.13.0)
  -h, --help         Show this help

Environment:
  DEFAULT_PYTHON_VERSION  Default Python version (default: 3.14.4)
USAGE
}

usage_error() {
  printf 'pyenv.sh: %s\n\n' "$1" >&2
  usage >&2
  exit 2
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      install | upgrade)
        ACTION="$1"
        ;;
      --version)
        shift
        if [ "$#" -eq 0 ] || [ -z "$1" ]; then
          usage_error "--version requires a value"
        fi
        PYTHON_VERSION="$1"
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        usage_error "unknown argument: $1"
        ;;
    esac
    shift
  done
}

resolve_python_version() {
  if [ -n "$PYTHON_VERSION" ]; then
    return
  fi
  read -r -p "Enter the Python version to install (default: ${DEFAULT_PYTHON_VERSION}): " user_input
  PYTHON_VERSION="${user_input:-$DEFAULT_PYTHON_VERSION}"
}

load_pyenv() {
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
}

install_pyenv_deps() {
  sudo apt install -y make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
}

setup_pyenv_shell() {
  if ! grep -q 'PYENV_ROOT' "$HOME/.zshrc" 2>/dev/null; then
    cat >> "$HOME/.zshrc" <<'EOF'
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
EOF
  fi
}

install_python_version() {
  echo "Installing Python ${PYTHON_VERSION} (this may take a while)..."
  pyenv install --skip-existing "$PYTHON_VERSION"
  pyenv global "$PYTHON_VERSION"

  python -m ensurepip --upgrade
  python -m pip install --upgrade pip

  python -m pip install --user pipx
  python -m pipx ensurepath
  export PATH="$HOME/.local/bin:$PATH"

  pipx install virtualenv || pipx upgrade virtualenv
  pipx install poetry || pipx upgrade poetry

  echo "Python $(python --version) installed."
  pipx list
  poetry --version
  virtualenv --version
}

do_install() {
  resolve_python_version
  install_pyenv_deps

  if [ -d "$HOME/.pyenv/.git" ]; then
    git -C "$HOME/.pyenv" pull --ff-only
  else
    curl -fsSL https://pyenv.run | bash
  fi

  setup_pyenv_shell
  load_pyenv
  install_python_version
}

do_upgrade() {
  resolve_python_version

  if ! command -v pyenv >/dev/null 2>&1; then
    load_pyenv
  fi

  if ! command -v pyenv >/dev/null 2>&1; then
    echo "pyenv not found — run install first." >&2
    exit 1
  fi

  echo "Updating pyenv..."
  git -C "$HOME/.pyenv" pull --ff-only 2>/dev/null || true

  install_python_version
}

parse_args "$@"

case "$ACTION" in
  install)  do_install ;;
  upgrade)  do_upgrade ;;
  *)        usage_error "unknown action: $ACTION" ;;
esac
