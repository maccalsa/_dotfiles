#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

stow_package() {
  local package="$1"

  echo "Stowing $package"
  stow --dir="$SCRIPT_DIR/stow" --target="$HOME" "$package"
}

stow_package bat
if command -v bat >/dev/null 2>&1; then
  bat cache --build
fi

#stow_package nvim
stow_package git

# ~/.local/bin: x_* tools, x_ launcher, _x_manifest (same as zsh_setup.sh)
stow_package scripts

