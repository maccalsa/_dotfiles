#!/bin/bash

set -e

# install_neovim.sh
#

echo "[1/5] Installing dependencies for building Neovim"
sudo apt update
sudo apt install -y ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip curl doxygen

echo "[2/5] Cloning Neovim repository"
if [ ! -d "$HOME/neovim" ]; then
    git clone https://github.com/neovim/neovim.git "$HOME/neovim"
else
    echo "✅ Neovim repository already cloned."
fi

echo "[3/5] Building Neovim from source"
cd "$HOME/neovim"
git checkout stable
make CMAKE_BUILD_TYPE=Release

echo "[4/5] Installing Neovim"
sudo make install

echo "[5/5] Cleaning up"
cd ..
rm -rf "$HOME/neovim"

echo "🎉 Neovim installation complete!"


