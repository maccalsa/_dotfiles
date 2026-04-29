#!/bin/bash

set -euo pipefail

DEFAULT_NIXPKGS_REF="github:NixOS/nixpkgs/nixos-unstable"
read -r -p "Enter the nixpkgs flake ref to use (default: $DEFAULT_NIXPKGS_REF): " NIXPKGS_REF
NIXPKGS_REF=${NIXPKGS_REF:-$DEFAULT_NIXPKGS_REF}

# ─────────────────────────────────────────────
# Install Nix (multi-user / daemon mode)
# ─────────────────────────────────────────────
if ! command -v nix &> /dev/null; then
  echo "🔧 Installing Nix package manager..."
  sh <(curl -L https://nixos.org/nix/install) --daemon
else
  echo "✅ Nix already installed."
fi

# ─────────────────────────────────────────────
# Load nix environment
# ─────────────────────────────────────────────
# Load nix profile (once installed)
if [ -f /etc/profile.d/nix.sh ]; then
  . /etc/profile.d/nix.sh
elif [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi

# ─────────────────────────────────────────────
# Enable modern Nix commands for this user
# ─────────────────────────────────────────────
mkdir -p "$HOME/.config/nix"
NIX_CONF="$HOME/.config/nix/nix.conf"
touch "$NIX_CONF"

if ! grep -q '^experimental-features = .*nix-command.*flakes' "$NIX_CONF"; then
  echo "experimental-features = nix-command flakes" >> "$NIX_CONF"
fi

# ─────────────────────────────────────────────
# Install tools (with modern CLI)
# ─────────────────────────────────────────────
echo "📦 Installing dev tools via Nix..."

packages=(
  "$NIXPKGS_REF#atuin"
  "$NIXPKGS_REF#bat"
  "$NIXPKGS_REF#bottom"
  "$NIXPKGS_REF#bun"
  "$NIXPKGS_REF#ctlptl"
  "$NIXPKGS_REF#delta"
  "$NIXPKGS_REF#difftastic"
  "$NIXPKGS_REF#direnv"
  "$NIXPKGS_REF#dust"
  "$NIXPKGS_REF#eza"
  "$NIXPKGS_REF#fd"
  "$NIXPKGS_REF#fzf"
  "$NIXPKGS_REF#gh"
  "$NIXPKGS_REF#glow"
  "$NIXPKGS_REF#gum"
  "$NIXPKGS_REF#httpie"
  "$NIXPKGS_REF#hyperfine"
  "$NIXPKGS_REF#jq"
  "$NIXPKGS_REF#jsonnet"
  "$NIXPKGS_REF#just"
  "$NIXPKGS_REF#kind"
  "$NIXPKGS_REF#kubectl"
  "$NIXPKGS_REF#kubernetes-helm"
  "$NIXPKGS_REF#lazydocker"
  "$NIXPKGS_REF#lazygit"
  "$NIXPKGS_REF#lsof"
  "$NIXPKGS_REF#mprocs"
  "$NIXPKGS_REF#navi"
  "$NIXPKGS_REF#nix-direnv"
  "$NIXPKGS_REF#pay-respects"
  "$NIXPKGS_REF#procs"
  "$NIXPKGS_REF#ripgrep"
  "$NIXPKGS_REF#sd"
  "$NIXPKGS_REF#starship"
  "$NIXPKGS_REF#tealdeer"
  "$NIXPKGS_REF#tokei"
  "$NIXPKGS_REF#viddy"
  "$NIXPKGS_REF#watchexec"
  "$NIXPKGS_REF#xh"
  "$NIXPKGS_REF#yq-go"
  "$NIXPKGS_REF#zip"
  "$NIXPKGS_REF#zoxide"
)

nix --extra-experimental-features 'nix-command flakes' profile install "${packages[@]}"

echo "✅ Done installing Nix tools."

echo
echo "🎉 Nix setup complete!"
echo "------------------------------------------------------------"
echo "If you just installed Nix for the first time:"
echo
echo "👉 Please start a new shell session, then run:"
echo "   nix --version"
echo "   nix profile list"
echo
echo "This will confirm your installation and environment is working."
echo "------------------------------------------------------------"
