#!/usr/bin/env bash

set -euo pipefail

NVIM_REPO="${NVIM_REPO:-https://github.com/neovim/neovim.git}"
NVIM_REF="${NVIM_REF:-stable}"
NVIM_SRC="${NVIM_SRC:-$HOME/neovim}"
DOTFILES_NVIM_CONFIG="${DOTFILES_NVIM_CONFIG:-$HOME/_dotfiles/stow/nvim/.config/nvim}"
NVIM_CONFIG="${NVIM_CONFIG:-$HOME/.config/nvim}"

step() {
  printf '\n[%s] %s\n' "$1" "$2"
}

run_nvim_or_fail() {
  local description="$1"
  shift

  local log_file
  log_file="$(mktemp)"

  set +e
  "$@" >"$log_file" 2>&1
  local status=$?
  set -e

  if [ "$status" -ne 0 ] || grep -Eq 'Failed to run `config`|Error detected while processing|E[0-9]{3,}:' "$log_file"; then
    printf '\nNeovim check failed: %s\n\n' "$description" >&2
    sed -n '1,160p' "$log_file" >&2
    rm -f "$log_file"
    exit 1
  fi

  sed -n '1,80p' "$log_file"
  rm -f "$log_file"
}

step "1/7" "Installing Neovim build and plugin runtime dependencies"
if ! sudo -v; then
  printf 'This installer needs sudo. Re-run it from an interactive terminal so sudo can prompt for your password.\n' >&2
  exit 1
fi

sudo apt update
sudo apt install -y \
  autoconf \
  automake \
  build-essential \
  cmake \
  curl \
  doxygen \
  fd-find \
  gettext \
  git \
  libtool \
  libtool-bin \
  ninja-build \
  nodejs \
  npm \
  pkg-config \
  python3 \
  python3-pip \
  python3-venv \
  ripgrep \
  unzip

if ! command -v tree-sitter >/dev/null 2>&1; then
  if apt-cache show tree-sitter-cli >/dev/null 2>&1; then
    sudo apt install -y tree-sitter-cli
  else
    sudo npm install -g tree-sitter-cli
  fi
fi

step "2/7" "Fetching Neovim source"
if [ -d "$NVIM_SRC/.git" ]; then
  git -C "$NVIM_SRC" fetch --tags --force origin
else
  rm -rf "$NVIM_SRC"
  git clone "$NVIM_REPO" "$NVIM_SRC"
fi

step "3/7" "Building Neovim from $NVIM_REF"
git -C "$NVIM_SRC" checkout --force "$NVIM_REF"
git -C "$NVIM_SRC" clean -fdx
make -C "$NVIM_SRC" CMAKE_BUILD_TYPE=Release

step "4/7" "Installing Neovim"
sudo make -C "$NVIM_SRC" install
nvim --version | sed -n '1,3p'

step "5/7" "Ensuring dotfiles Neovim config is available"
if [ ! -e "$NVIM_CONFIG" ]; then
  if [ ! -d "$DOTFILES_NVIM_CONFIG" ]; then
    printf 'Expected Neovim config not found at %s\n' "$DOTFILES_NVIM_CONFIG" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$NVIM_CONFIG")"
  ln -s "$DOTFILES_NVIM_CONFIG" "$NVIM_CONFIG"
fi

step "6/7" "Clearing incompatible Treesitter cache from older installs"
rm -rf "$HOME/.local/share/nvim/lazy/nvim-treesitter"
rm -f "$HOME/.local/share/nvim/site/parser/jsonc.so"
rm -f "$HOME/.local/share/nvim/site/parser-info/jsonc.revision"
rm -rf "$HOME/.local/share/nvim/site/queries/jsonc"

step "7/7" "Restoring plugins and checking startup"
run_nvim_or_fail \
  "Lazy restore" \
  nvim --headless "+lua require('lazy').restore({ wait = true, show = false })" +qa

run_nvim_or_fail \
  "startup" \
  nvim --headless "+lua print('nvim startup ok')" +qa

printf '\nNeovim installation complete.\n'


