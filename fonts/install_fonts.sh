#!/bin/bash

FONTS_DIR="$HOME/.local/share/fonts"        
mkdir -p $FONTS_DIR

# Install JetBrains Mono Nerd Font
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip -O jetbrains-nerd-font.zip
unzip jetbrains-nerd-font.zip -d $FONTS_DIR/
rm jetbrains-nerd-font.zip
# Install MesloLGS Nerd Font
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf -O $FONTS_DIR/
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf -O $FONTS_DIR/
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf -O $FONTS_DIR/
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf -O $FONTS_DIR/

fc-cache -fv

fc-cache list | grep "MesloLGS"
fc-cache list | grep "JetBrains"

