#!/usr/bin/env bash
set -e

# Fetch IntelliJ Ultimate's latest download URL
IDEA_URL=$(curl -s "https://data.services.jetbrains.com/products/releases?code=IIU&latest=true&type=release" | jq -r '.IIU[0].downloads.linux.link')

# Vars
IDEA_TAR="ideaIU.tar.gz"
INSTALL_DIR="/opt/idea-IU"
BIN_DIR="/usr/local/bin"

# Install dependencies
sudo apt update && sudo apt install -y jq wget

# Download IntelliJ Ultimate
echo "📥 Downloading IntelliJ IDEA Ultimate from $IDEA_URL"
wget -O "$IDEA_TAR" "$IDEA_URL"

# Extract to /opt
echo "📂 Extracting IntelliJ IDEA Ultimate..."
sudo tar -xzf "$IDEA_TAR" -C /opt/
sudo mv /opt/idea-IU-* "$INSTALL_DIR"

# Cleanup downloaded archive
rm "$IDEA_TAR"

# Create symbolic link
echo "🔗 Creating symbolic link..."
sudo ln -sf "$INSTALL_DIR/bin/idea.sh" "$BIN_DIR/idea"

# Desktop Entry
echo "🖥️ Creating desktop entry..."
cat <<EOF | sudo tee /usr/share/applications/jetbrains-idea-ultimate.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=IntelliJ IDEA Ultimate
Icon=$INSTALL_DIR/bin/idea.svg
Exec="$INSTALL_DIR/bin/idea.sh" %f
Comment=IntelliJ IDEA Ultimate Edition
Categories=Development;IDE;
Terminal=false
StartupWMClass=jetbrains-idea
EOF

echo "🚀 IntelliJ IDEA Ultimate installed successfully!"

