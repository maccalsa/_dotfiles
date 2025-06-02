#!/bin/bash

# Ensure script fails on error
set -e

# Upgrade the system
sudo apt update

# Upgrade the system
sudo apt upgrade -y

# Install necessary dependencies first
sudo apt update

# "${BASH_SOURCE[0]}": This variable holds the path to the current script as it was invoked. It could be a relative or absolute path.
# dirname "...": This command extracts the directory part of the path.
# cd "...": This changes the directory to the script's directory.
# &> /dev/null: This suppresses any output from the cd command.
# pwd: This prints the present working directory (which is now the script's actual directory, resolved to an absolute path).
# $(...): This is command substitution, capturing the output of the commands inside.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "[1/4] Installing dependencies (git, curl, stow, unzip, zsh)..."
sudo apt install -y git stow curl wget zip unzip zsh

## If runnong inside kvm, yuo'll need guest extensions
## sudo apt install spice-vdagent qemu-guest-agent


echo "[2/4] Installing Nerd Fonts (JetBrains & Meslo)..."
${SCRIPT_DIR}/fonts/install_fonts.sh

echo "[3/4] Installing Alacritty Terminal..."
sudo apt install -y alacritty

echo "[4/4] Stowing dotfiles for alacritty"
stow --dir=stow --target="$HOME" alacritty

echo "Initial terminal setup complete!"
echo "You can now launch Alacritty and proceed to install Zsh & other configs."
echo "1) Run ./zsh_setup.sh to install Zsh and other configs."



