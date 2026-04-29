#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "[1/5] Installing tmux"
sudo apt install -y tmux

# Install tmux plugin manager
echo "[2/5] Installing tmux plugin manager"
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
else
    echo "tmux plugin manager already installed."
fi

echo "[3/5] Installing tmux theme"
if [ ! -d "$HOME/.tmux/plugins/tmux" ]; then
    git clone https://github.com/catppuccin/tmux "$HOME/.tmux/plugins/tmux"
else
    echo "tmux theme already installed."
fi

echo "[4/5] Stowing tmux config"
stow --dir="$REPO_ROOT/stow" --target="$HOME" tmux

# Install tmux plugins
echo "[5/5] Installing tmux plugins"
echo "Run in a new terminal: ~/.tmux/plugins/tpm/scripts/install_plugins.sh"

