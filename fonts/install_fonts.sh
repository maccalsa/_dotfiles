#!/bin/bash

FONTS_DIR="$HOME/.local/share/fonts"        
mkdir -p "$FONTS_DIR"

# Install JetBrains Mono Nerd Font
wget "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip" -O "jetbrains-nerd-font.zip"
unzip "jetbrains-nerd-font.zip" -d "$FONTS_DIR/"
rm "jetbrains-nerd-font.zip"

# Install MesloLGS Nerd Font
wget "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf" \
    -O "$FONTS_DIR/MesloLGS_NF_Regular.ttf"
wget "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf" \
    -O "$FONTS_DIR/MesloLGS_NF_Bold.ttf"
wget "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf" \
    -O "$FONTS_DIR/MesloLGS_NF_Italic.ttf"
wget "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf" \
    -O "$FONTS_DIR/MesloLGS_NF_Bold_Italic.ttf"

# Refresh the font cache
fc-cache -fv

# Verify installation
fc-list | grep -i "MesloLGS"
fc-list | grep -i "JetBrains"

echo "Fonts installed successfully!"



