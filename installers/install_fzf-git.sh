#!/bin/bash

set -e

# install_fzf-git.sh
#

echo "Installing fzf-git"

if [ ! -d "$HOME/.fzf-git" ]; then
  git clone https://github.com/junegunn/fzf-git.sh.git "$HOME/.fzf-git"
else
  echo "fzf-git already installed."
fi