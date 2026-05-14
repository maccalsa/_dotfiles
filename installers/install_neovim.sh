#!/usr/bin/env bash

set -euo pipefail

NVIM_REPO="${NVIM_REPO:-https://github.com/neovim/neovim.git}"
NVIM_SRC="${NVIM_SRC:-$HOME/neovim}"
DOTFILES_NVIM_CONFIG="${DOTFILES_NVIM_CONFIG:-$HOME/_dotfiles/stow/nvim/.config/nvim}"
NVIM_CONFIG="${NVIM_CONFIG:-$HOME/.config/nvim}"

ACTION="install"
NVIM_REF="${NVIM_REF:-}"
RESTORE_PLUGINS=1
CHECK_STARTUP=1

usage() {
  cat <<'USAGE'
Usage: install_neovim.sh [install|uninstall|reinstall] [options]

Actions:
  install              Install Neovim. This is the default action.
  uninstall            Remove this script's source-built Neovim install.
  reinstall            Uninstall, then install.

Options:
  --latest             Install the latest stable Neovim release.
  --ref REF            Install a specific Neovim tag, branch, or commit.
  --no-plugin-restore  Skip Lazy plugin restore.
  --no-startup-check   Skip headless startup check.
  -h, --help           Show this help.

Environment:
  NVIM_REPO            Neovim git repository. Default: https://github.com/neovim/neovim.git
  NVIM_REF             Neovim ref to install. Defaults to latest stable release.
  NVIM_SRC             Source checkout path. Default: $HOME/neovim
USAGE
}

step() {
  printf '\n[%s] %s\n' "$1" "$2"
}

usage_error() {
  printf 'install_neovim.sh: %s\n\n' "$1" >&2
  usage >&2
  exit 2
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      install | uninstall | reinstall)
        ACTION="$1"
        ;;
      --latest)
        NVIM_REF=""
        ;;
      --ref)
        shift
        if [ "$#" -eq 0 ] || [ -z "$1" ]; then
          usage_error "--ref requires a value"
        fi
        NVIM_REF="$1"
        ;;
      --no-plugin-restore)
        RESTORE_PLUGINS=0
        ;;
      --no-startup-check)
        CHECK_STARTUP=0
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

require_sudo() {
  if sudo -v; then
    return
  fi

  printf 'This installer needs sudo. Re-run it from an interactive terminal so sudo can prompt for your password.\n' >&2
  exit 1
}

show_current_nvim() {
  local label="$1"

  step "$label" "Current Neovim on PATH"
  if command -v nvim >/dev/null 2>&1; then
    command -v nvim
    nvim --version | sed -n '1,3p'
  else
    printf 'nvim not found on PATH\n'
  fi
}

install_tree_sitter_cli() {
  if command -v tree-sitter >/dev/null 2>&1; then
    return
  fi

  if apt-cache show tree-sitter-cli >/dev/null 2>&1; then
    sudo apt install -y tree-sitter-cli
    return
  fi

  if command -v nix >/dev/null 2>&1; then
    if nix --extra-experimental-features 'nix-command flakes' profile install nixpkgs#tree-sitter --priority 4; then
      return
    fi
  fi

  if command -v cargo >/dev/null 2>&1; then
    cargo install tree-sitter-cli
    return
  fi

  if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    local node_major
    node_major="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || printf 0)"
    if [ "$node_major" -ge 16 ]; then
      mkdir -p "$HOME/.local"
      npm install --global --prefix "$HOME/.local" tree-sitter-cli
      return
    fi
  fi

  printf 'tree-sitter CLI was not installed. Continuing because Neovim can still build without it.\n' >&2
  printf 'Install a newer Node, Rust cargo, or Nix tree-sitter if parser generation is needed later.\n' >&2
}

install_dependencies() {
  step "deps" "Installing Neovim build and plugin runtime dependencies"
  require_sudo

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

  install_tree_sitter_cli
}

resolve_latest_stable_ref() {
  local release_api="https://api.github.com/repos/neovim/neovim/releases/latest"
  local latest_ref=""

  if command -v curl >/dev/null 2>&1; then
    latest_ref="$(curl -fsSL "$release_api" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
  fi

  if [ -z "$latest_ref" ]; then
    latest_ref="$(git ls-remote --tags --refs "$NVIM_REPO" 'v[0-9]*.[0-9]*.[0-9]*' \
      | sed 's#.*refs/tags/##' \
      | sort -V \
      | tail -n 1)"
  fi

  if [ -z "$latest_ref" ]; then
    printf 'Unable to resolve the latest stable Neovim release. Try --ref v0.11.5.\n' >&2
    exit 1
  fi

  printf '%s\n' "$latest_ref"
}

fetch_source() {
  step "source" "Fetching Neovim source"
  if [ -d "$NVIM_SRC/.git" ]; then
    git -C "$NVIM_SRC" fetch --tags --force origin
  else
    rm -rf "$NVIM_SRC"
    git clone "$NVIM_REPO" "$NVIM_SRC"
  fi
}

build_and_install() {
  local ref="$1"

  step "build" "Building Neovim from $ref"
  git -C "$NVIM_SRC" checkout --force "$ref"
  git -C "$NVIM_SRC" clean -fdx
  make -C "$NVIM_SRC" CMAKE_BUILD_TYPE=Release

  step "install" "Installing Neovim"
  require_sudo
  sudo make -C "$NVIM_SRC" install
}

ensure_config() {
  step "config" "Ensuring dotfiles Neovim config is available"
  if [ ! -e "$NVIM_CONFIG" ]; then
    if [ ! -d "$DOTFILES_NVIM_CONFIG" ]; then
      printf 'Expected Neovim config not found at %s\n' "$DOTFILES_NVIM_CONFIG" >&2
      exit 1
    fi

    mkdir -p "$(dirname "$NVIM_CONFIG")"
    ln -s "$DOTFILES_NVIM_CONFIG" "$NVIM_CONFIG"
  fi
}

clear_treesitter_cache() {
  step "cache" "Clearing incompatible Treesitter cache from older installs"
  rm -rf "$HOME/.local/share/nvim/lazy/nvim-treesitter"
  rm -f "$HOME/.local/share/nvim/site/parser/jsonc.so"
  rm -f "$HOME/.local/share/nvim/site/parser-info/jsonc.revision"
  rm -rf "$HOME/.local/share/nvim/site/queries/jsonc"
}

restore_and_check() {
  if [ "$RESTORE_PLUGINS" -eq 1 ]; then
    step "plugins" "Restoring plugins"
    run_nvim_or_fail \
      "Lazy restore" \
      nvim --headless "+lua require('lazy').restore({ wait = true, show = false })" +qa
  else
    step "plugins" "Skipping plugin restore"
  fi

  if [ "$CHECK_STARTUP" -eq 1 ]; then
    step "check" "Checking startup"
    run_nvim_or_fail \
      "startup" \
      nvim --headless "+lua print('nvim startup ok')" +qa
  else
    step "check" "Skipping startup check"
  fi
}

uninstall_neovim() {
  step "uninstall" "Removing source-built Neovim install"
  require_sudo

  local manifest="$NVIM_SRC/build/install_manifest.txt"
  if [ -f "$manifest" ]; then
    sudo xargs -r rm -f <"$manifest"
  else
    sudo rm -f /usr/local/bin/nvim
    sudo rm -f /usr/local/share/applications/nvim.desktop
    sudo rm -f /usr/local/share/man/man1/nvim.1
    sudo rm -rf /usr/local/lib/nvim
    sudo rm -rf /usr/local/share/nvim
  fi

  printf 'Neovim uninstall step complete.\n'
}

install_neovim() {
  show_current_nvim "before"
  install_dependencies

  local ref="$NVIM_REF"
  if [ -z "$ref" ]; then
    step "version" "Resolving latest stable Neovim release"
    ref="$(resolve_latest_stable_ref)"
  fi
  printf 'Installing Neovim ref: %s\n' "$ref"

  fetch_source
  build_and_install "$ref"
  show_current_nvim "after"
  ensure_config
  clear_treesitter_cache
  restore_and_check

  printf '\nNeovim installation complete.\n'
}

parse_args "$@"

case "$ACTION" in
  install)
    install_neovim
    ;;
  uninstall)
    show_current_nvim "before"
    uninstall_neovim
    show_current_nvim "after"
    ;;
  reinstall)
    show_current_nvim "before"
    uninstall_neovim
    install_neovim
    ;;
esac
