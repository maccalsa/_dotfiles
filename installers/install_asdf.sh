#!/bin/bash

set -euo pipefail

echo "🔧 Installing dependencies for asdf..."

sudo apt update
sudo apt install -y git curl build-essential autoconf m4 libncurses5-dev \
    libwxgtk3.0-gtk3-dev libssl-dev libsqlite3-dev libreadline-dev zlib1g-dev

echo "⬇️ Installing asdf..."

if [ ! -d "$HOME/.asdf" ]; then
    git clone https://github.com/asdf-vm/asdf.git "$HOME/.asdf" --branch v0.14.0
else
    echo "✅ asdf already installed."
fi

echo "🔗 Configuring shell..."

shell_config="${HOME}/.zshrc"

if ! grep -q 'asdf setup' "$shell_config" 2>/dev/null; then
    {
        echo ''
        echo '# asdf setup'
        echo '. "$HOME/.asdf/asdf.sh"'
    } >> "$shell_config"
fi

echo "✅ asdf installed successfully. Reload your shell or run:"
echo "source $shell_config"

