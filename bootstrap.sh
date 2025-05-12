#!/bin/bash

# Ensure script fails on error
set -e

# Upgrade the system
sudo apt update

# Upgrade the system
sudo apt upgrade -y

# Install necessary dependencies first
sudo apt update

echo "[1/4] Installing dependencies (git, curl, stow, unzip, zsh)..."
sudo apt install -y git stow curl wget unzip zsh

echo "[2/4] Installing Nerd Fonts (JetBrains & Meslo)..."
./fonts/install_fonts.sh

echo "[3/4] Installing Alacritty Terminal..."
sudo apt install -y alacritty

echo "[4/4] Stowing dotfiles for alacritty"
stow --dir=stow --target="$HOME" alacritty

echo "Initial terminal setup complete!"
echo "You can now launch Alacritty and proceed to install Zsh & other configs."
echo "1) Run ./zsh_setup.sh to install Zsh and other configs."



