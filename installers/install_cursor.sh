#!/usr/bin/env bash

# Install Cursor IDE through Cursor's apt repository.

set -euo pipefail

CURSOR_APT_KEY_URL="https://downloads.cursor.com/keys/anysphere.asc"
CURSOR_APT_REPO="https://downloads.cursor.com/aptrepo"
CURSOR_APT_KEYRING="/etc/apt/keyrings/cursor.gpg"
CURSOR_APT_LIST="/etc/apt/sources.list.d/cursor.list"
LEGACY_APPIMAGE_PATH="/opt/cursor.AppImage"
LEGACY_DESKTOP_ENTRY="/usr/share/applications/cursor.desktop"

echo "📦 Installing dependencies for Cursor apt repository..."
sudo apt update
sudo apt install -y ca-certificates curl gpg

echo "🔐 Installing Cursor apt signing key..."
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL "$CURSOR_APT_KEY_URL" | gpg --dearmor | sudo tee "$CURSOR_APT_KEYRING" >/dev/null
sudo chmod 0644 "$CURSOR_APT_KEYRING"

echo "📝 Registering Cursor apt repository..."
echo "deb [arch=amd64,arm64 signed-by=${CURSOR_APT_KEYRING}] ${CURSOR_APT_REPO} stable main" |
  sudo tee "$CURSOR_APT_LIST" >/dev/null

echo "⬇️  Installing Cursor..."
sudo apt update
sudo apt install -y cursor

if [ -L /usr/local/bin/cursor ] && [ "$(readlink /usr/local/bin/cursor)" = "$LEGACY_APPIMAGE_PATH" ]; then
  echo "🧹 Removing old AppImage cursor symlink..."
  sudo rm -f /usr/local/bin/cursor
fi

if [ -f "$LEGACY_APPIMAGE_PATH" ]; then
  echo "🧹 Removing old Cursor AppImage..."
  sudo rm -f "$LEGACY_APPIMAGE_PATH"
fi

if [ -f "$LEGACY_DESKTOP_ENTRY" ] && grep -q "$LEGACY_APPIMAGE_PATH" "$LEGACY_DESKTOP_ENTRY"; then
  echo "🧹 Removing old AppImage desktop entry..."
  sudo rm -f "$LEGACY_DESKTOP_ENTRY"
fi

echo "✅ Cursor installed."
echo "   GUI: application menu → Cursor"
echo "   Terminal: cursor ."
