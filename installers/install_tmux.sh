#!/bin/bash

echo "[1/5] Installing tmux"
sudo apt install -y tmux

# Install tmux plugin manager
echo "[2/5] Installing tmux plugin manager"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

echo "[3/5] Installing tmux theme"
git clone https://github.com/catppuccin/tmux ~/.tmux/plugins/tmux

echo "[4/5] Stowing tmux config"
stow --dir=../stow --target="$HOME" tmux

# Install tmux plugins
echo "[5/5] Installing tmux plugins"
echo "Run in a new terminal: ~/.tmux/plugins/tpm/scripts/install_plugins.sh"

