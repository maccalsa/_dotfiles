#!/bin/bash

set -e

# post_install_software.sh
#

## Configure bat

echo "💡 Configuring bat"
stow --dir=stow --target="$HOME" bat
bat cache --build
# > `bat --list-themes | fzf --preview="bat --theme={} --color=always /path/to/file"`

# Configure neovim
echo "💡 Configuring neovim"
stow --dir=stow --target="$HOME" nvim

echo "💡 Configuring git"
stow --dir=stow --target="$HOME" git

echo "💡 Configuring bashhub"
stow --dir=stow --target="$HOME" bashhub

echo "💡 Configuring espanso"
stow --dir=stow --target="$HOME" epsanso
espanso service register
expanso start

