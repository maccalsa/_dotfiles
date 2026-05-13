#!/usr/bin/env bash
set -euo pipefail

APPIMAGE="${1:-}"

if [[ -z "$APPIMAGE" ]]; then
  echo "Usage: $0 /path/to/App.AppImage"
  exit 1
fi

if [[ ! -f "$APPIMAGE" ]]; then
  echo "File not found: $APPIMAGE"
  exit 1
fi

APP_NAME="$(basename "$APPIMAGE" .AppImage)"
INSTALL_DIR="$HOME/Applications"
TARGET="$INSTALL_DIR/$APP_NAME.AppImage"
DESKTOP_FILE="$HOME/.local/share/applications/$APP_NAME.desktop"

mkdir -p "$INSTALL_DIR"
mkdir -p "$HOME/.local/share/applications"

cp "$APPIMAGE" "$TARGET"
chmod +x "$TARGET"

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=$APP_NAME
Exec=$TARGET
Type=Application
Categories=Utility;
Terminal=false
EOF

chmod +x "$DESKTOP_FILE"

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$HOME/.local/share/applications" || true
fi

echo "Installed: $APP_NAME"
echo "AppImage:  $TARGET"
echo "Launcher:  $DESKTOP_FILE"
echo
echo "You should now find it in your application menu."
