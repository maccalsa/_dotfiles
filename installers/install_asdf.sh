#!/bin/bash

set -e

echo "🔧 Installing dependencies for asdf..."

sudo apt update
sudo apt install -y git curl build-essential autoconf m4 libncurses5-dev \
    libwxgtk3.0-gtk3-dev libssl-dev libsqlite3-dev libreadline-dev zlib1g-dev

echo "⬇️ Installing asdf..."

git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0

echo "🔗 Configuring shell..."

shell_config="${HOME}/.$(basename "$SHELL")rc"

{
    echo ''
    echo '# asdf setup'
    echo '. "$HOME/.asdf/asdf.sh"'
    echo '. "$HOME/.asdf/completions/asdf.bash"'
} >> "$shell_config"

echo "✅ asdf installed successfully. Reload your shell or run:"
echo "source $shell_config"

