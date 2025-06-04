#!/bin/bash

# ─────────────────────────────────────────────
# Set your desired stable Nixpkgs version here
# You can change this to 24.05 later, for example
# Check latest version at: https://status.nixos.org/
DEFAULT_NIXPKGS_VERSION="24.11"
read -p "Enter the Nixpkgs version to install (default: $DEFAULT_NIXPKGS_VERSION): " NIXPKGS_VERSION
NIXPKGS_VERSION=${NIXPKGS_VERSION:-$DEFAULT_NIXPKGS_VERSION}

CHANNEL_NAME="nixpkgs"
CHANNEL_URL="https://nixos.org/channels/nixpkgs-${NIXPKGS_VERSION}-darwin"


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
# Add stable channel
# ─────────────────────────────────────────────

if ! nix-channel --list | grep -q "^${CHANNEL_NAME}"; then
  echo "📦 Adding Nixpkgs ${NIXPKGS_VERSION} channel..."
  nix-channel --add "$CHANNEL_URL" "$CHANNEL_NAME"
else
  echo "🔄 Updating existing channel: $CHANNEL_NAME"
fi

nix-channel --update

# ─────────────────────────────────────────────
# Install tools (with modern CLI)
# ─────────────────────────────────────────────
echo "📦 Installing dev tools via Nix..."
nix --extra-experimental-features 'nix-command flakes' profile install \
  nixpkgs#fzf \
  nixpkgs#zoxide \
  nixpkgs#bat \
  nixpkgs#pay-respects \
  nixpkgs#lazydocker \
  nixpkgs#lazygit \
  nixpkgs#fd \
  nixpkgs#httpie \
  nixpkgs#eza \
  nixpkgs#jq \
  nixpkgs#lsof \
  nixpkgs#kind \
  nixpkgs#kubectl \
  nixpkgs#kubernetes-helm \
  nixpkgs#bottom \
  nixpkgs#jsonnet \
  nixpkgs#bun \
  nixpkgs#ctlptl \
  nixpkgs#navi \
  nixpkgs#glow \
  nixpkgs#ripgrep \
  nixpkgs#espanco \

echo "✅ Done installing Nix tools."

echo
echo "🎉 Nix setup complete!"
echo "------------------------------------------------------------"
echo "If you just installed Nix for the first time:"
echo
echo "👉 Please start a new shell session, then run:"
echo "   nix-shell -p nix-info --run \"nix-info -m\""
echo
echo "This will confirm your installation and environment is working."
echo "------------------------------------------------------------"
