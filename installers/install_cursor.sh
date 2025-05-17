#!/bin/bash

set -e

# Update and install required dependencies
sudo apt update
sudo apt install -y libfuse2 wget

CURSOR_APPIMAGE_PATH="/opt/cursor.AppImage"

# Make the AppImage executable
sudo chmod +x "$CURSOR_APPIMAGE_PATH"

# Create a desktop entry for Cursor
sudo tee /usr/share/applications/cursor.desktop > /dev/null <<EOL
[Desktop Entry]
Name=Cursor
Exec=$CURSOR_APPIMAGE_PATH --no-sandbox
Icon=
Type=Application
Categories=Development;
EOL

# Create a command-line alias for Cursor (optional)
SHELL_RC_FILE="$HOME/.zshrc"
if [ -n "$ZSH_VERSION" ]; then
  SHELL_RC_FILE="$HOME/.zshrc"
fi

echo "alias cursor='$CURSOR_APPIMAGE_PATH --no-sandbox'" >> "$SHELL_RC_FILE"

# Source shell configuration
source "$SHELL_RC_FILE"

# Completion message
echo "Cursor AI installed successfully!"
echo "You can launch it via your application menu or by typing 'cursor' in the terminal."
