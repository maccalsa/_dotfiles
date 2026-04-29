#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

ask_yes_no() {
  local prompt="$1"
  local default="${2:-y}"
  local answer

  read -r -p "$prompt (Y/n): " answer
  answer=${answer:-$default}
  [[ "$answer" =~ ^[Yy]$ ]]
}

run_step() {
  local label="$1"
  local script="$2"

  echo
  echo "==> $label"
  bash "$script"
}

echo "This installer assumes bootstrap.sh and zsh_setup.sh have already run."
echo "If this is a fresh machine, restore SSH/GPG keys before installing the password store."

run_step "Installing language toolchains" "$SCRIPT_DIR/installers/install_languages.sh"
run_step "Installing tmux" "$SCRIPT_DIR/installers/install_tmux.sh"
run_step "Installing fzf-git" "$SCRIPT_DIR/installers/install_fzf-git.sh"

if ask_yes_no "Install pass and clone the password store? This requires restored SSH/GPG keys"; then
  run_step "Installing pass and password store" "$SCRIPT_DIR/installers/install_my_pass.sh"
fi

run_step "Installing Docker" "$SCRIPT_DIR/installers/install_docker.sh"
run_step "Installing Neovim" "$SCRIPT_DIR/installers/install_neovim.sh"
run_step "Installing Go/npm helper tools" "$SCRIPT_DIR/installers/install_tools.sh"
run_step "Installing curated Nix CLI tools" "$SCRIPT_DIR/nix/install_nix.sh"
run_step "Stowing app configuration" "$SCRIPT_DIR/post_install_software.sh"

echo
echo "Install complete. Open a new shell, then run the verification commands in README.md."