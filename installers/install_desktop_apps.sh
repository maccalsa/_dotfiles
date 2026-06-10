#!/bin/bash

# Optional GUI stack: Remmina (apt), Cursor desktop (apt), Cursor CLI (agent),
# snapd + Telegram Desktop (snap). Run from repo root via install_software.sh or
# directly: bash installers/install_desktop_apps.sh [install|upgrade]

set -euo pipefail

ACTION="install"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

usage() {
  cat <<'USAGE'
Usage: install_desktop_apps.sh [install|upgrade] [options]

Actions:
  install  Interactively install selected desktop apps (default)
  upgrade  Interactively upgrade installed apps to their latest available version

  -h, --help  Show this help

Apps managed:
  Remmina        — apt (remmina, remmina-plugin-rdp, remmina-plugin-vnc)
  Cursor desktop — apt (Cursor apt repo)
  Cursor CLI     — official installer script (re-run to upgrade)
  Telegram       — snap (telegram-desktop)
USAGE
}

usage_error() {
  printf 'install_desktop_apps.sh: %s\n\n' "$1" >&2
  usage >&2
  exit 2
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      install | upgrade)
        ACTION="$1"
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        usage_error "unknown argument: $1"
        ;;
    esac
    shift
  done
}

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

do_install() {
  sudo apt update

  if ask_yes_no "Install Remmina (remote desktop client via apt)?"; then
    sudo apt install -y remmina remmina-plugin-rdp remmina-plugin-vnc
  fi

  if ask_yes_no "Install Cursor desktop (apt package)?"; then
    bash "$SCRIPT_DIR/install_cursor.sh" install
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

  echo "✅ Desktop apps install finished."
}

do_upgrade() {
  sudo apt update

  if ask_yes_no "Upgrade Remmina?"; then
    sudo apt-get install -y --only-upgrade remmina remmina-plugin-rdp remmina-plugin-vnc
    echo "Remmina: $(remmina --version 2>/dev/null | head -1 || echo 'version unavailable')"
  fi

  if ask_yes_no "Upgrade Cursor desktop (apt)?"; then
    bash "$SCRIPT_DIR/install_cursor.sh" upgrade
  fi

  if ask_yes_no "Upgrade Cursor CLI (re-runs official installer)?"; then
    echo "📥 Running official Cursor installer (upgrades in-place)..."
    curl https://cursor.com/install -fsS | bash
    ensure_path_hint
  fi

  if ask_yes_no "Upgrade Telegram Desktop (snap)?"; then
    sudo snap refresh telegram-desktop
    echo "Telegram: $(snap list telegram-desktop 2>/dev/null | tail -1 || echo 'version unavailable')"
  fi

  echo "✅ Desktop apps upgrade finished."
}

parse_args "$@"

case "$ACTION" in
  install)  do_install ;;
  upgrade)  do_upgrade ;;
  *)        usage_error "unknown action: $ACTION" ;;
esac
