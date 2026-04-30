#!/bin/bash

# Install Cursor IDE (Linux x86_64 AppImage) to /opt and symlink cursor on PATH.

set -euo pipefail

CURSOR_DOWNLOAD_URL="https://cursor.com/download/linux-x64"
CURSOR_APPIMAGE_PATH="/opt/cursor.AppImage"
TMP_IMG="$(mktemp "${TMPDIR:-/tmp}/cursor.AppImage.XXXXXX")"

trap 'rm -f "$TMP_IMG"' EXIT

echo "📦 Installing dependencies for Cursor..."
sudo apt update
sudo apt install -y libfuse2 wget

echo "⬇️  Downloading Cursor AppImage..."
curl -fsSL "$CURSOR_DOWNLOAD_URL" -o "$TMP_IMG"
sudo mv "$TMP_IMG" "$CURSOR_APPIMAGE_PATH"
sudo chmod +x "$CURSOR_APPIMAGE_PATH"

echo "🔗 Symlinking cursor (terminal launcher)..."
sudo ln -sf "$CURSOR_APPIMAGE_PATH" /usr/local/bin/cursor

echo "📝 Desktop entry..."
sudo tee /usr/share/applications/cursor.desktop > /dev/null <<EOF
[Desktop Entry]
Name=Cursor
Exec=$CURSOR_APPIMAGE_PATH --no-sandbox %F
Comment=AI-enabled code editor
Icon=cursor
Type=Application
Categories=Development;IDE;
StartupWMClass=Cursor
EOF

echo "✅ Cursor installed."
echo "   GUI: application menu → Cursor"
echo "   Terminal: cursor ."
