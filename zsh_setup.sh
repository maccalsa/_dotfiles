#!/bin/bash

set -e

echo "🔧 [1/5] Installing zsh and essentials..."
sudo apt update
sudo apt install -y zsh git curl

echo "📁 [2/5] Creating zsh config folders..."
ZSH_CUSTOM="${ZDOTDIR:-$HOME}/.zsh"
mkdir -p "$ZSH_CUSTOM"

### --- Antidote Plugin Manager ---
if [ ! -d "$ZSH_CUSTOM/antidote" ]; then
    echo "📦 [3/5] Installing Antidote plugin manager..."
    git clone --depth=1 https://github.com/mattmc3/antidote.git "$ZSH_CUSTOM/antidote"
else
    echo "✅ [3/5] Antidote already installed."
fi

### --- Zsh Plugins ---
echo "📜 [4/5] Writing plugin list..."
cat > ~/.zsh_plugins.txt <<EOF
zsh-users/zsh-autosuggestions
zsh-users/zsh-syntax-highlighting
zsh-users/zsh-completions
romkatv/powerlevel10k
EOF

### --- Copy Scripts ---
stow --dir=stow --target=~/ scripts

echo "[5/5] Stowing dotfiles for zsh"
stow --dir=stow --target=~/ zshrc

### --- Fonts Reminder ---
echo "💡 Make sure you install a Nerd Font (e.g. MesloLGS NF) in your terminal!"

### --- Set Zsh as default shell ---
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "💬 [5/5] Setting Zsh as your default shell..."
    chsh -s $(which zsh)
fi

### --- First-Time Prompt Config ---
echo "🚀 Zsh is ready! Start a new shell to finish setup."
echo "⚡ On first run, you’ll see Powerlevel10k config. Choose 'Lean' for speed."
echo "🔑 Run ./install_software.sh to install software."
