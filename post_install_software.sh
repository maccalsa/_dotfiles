#!/bin/bash

set -e

# post_install_software.sh
#

## Configure bat

echo "💡 Configuring bat"
bat cache --build
# > `bat --list-themes | fzf --preview="bat --theme={} --color=always /path/to/file"`
stow --dir=stow --target=~/ bat

## Install neovim
echo "💡 Installing neovim"
./installers/install_neovim.sh

# Configure neovim
echo "💡 Configuring neovim"
stow --dir=stow --target=~/ neovim

echo "💡 Configuring git"
stow --dir=stow --target=~/ git

echo "💡 Installing your tools"
./installers/install_tools.sh

echo "💡 Configuring bashhub"
stow --dir=stow --target=~/ bashhub


