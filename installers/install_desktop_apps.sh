#!/bin/bash

# Optional GUI stack: Remmina (apt), Cursor desktop (apt), Cursor CLI (agent),
# snapd + Telegram Desktop (snap). Run from repo root via install_software.sh or
# directly: bash installers/install_desktop_apps.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

ask_yes_no() {
  local prompt="$1"
  local answer
  read -r -p "$prompt (Y/n): " answer
  answer=${answer:-y}
  [[ "$answer" =~ ^[Yy]$ ]]
}

ensure_path_hint() {
  if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo
    echo "Add Cursor CLI to PATH (then open a new shell):"
    echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc"
  fi
}

sudo apt update

if ask_yes_no "Install Remmina (remote desktop client via apt)?"; then
  sudo apt install -y remmina remmina-plugin-rdp remmina-plugin-vnc
fi

if ask_yes_no "Install Cursor desktop (apt package)?"; then
  bash "$SCRIPT_DIR/install_cursor.sh"
  if ask_yes_no "Stow Cursor IDE user settings from stow/cursor?"; then
    stow --dir="$REPO_ROOT/stow" --target="$HOME" cursor
  fi
fi

if ask_yes_no "Install Cursor CLI (agent)?"; then
  echo "📥 Running official Cursor installer (network)..."
  curl https://cursor.com/install -fsS | bash
  ensure_path_hint
  echo "Verify with: agent --version   (may need new shell)"
fi

if ask_yes_no "Install snapd and Telegram Desktop (snap)?"; then
  sudo apt install -y snapd
  if sudo systemctl is-enabled snapd.socket &>/dev/null; then
    sudo systemctl start snapd.socket || true
  fi
  echo "📱 Installing telegram-desktop..."
  sudo snap install telegram-desktop
fi

echo "✅ Desktop apps step finished."
