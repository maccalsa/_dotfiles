#!/usr/bin/env bash
set -e

# Add DBeaver official repo
echo "🐝 Adding DBeaver repository..."
wget -O - https://dbeaver.io/debs/dbeaver.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/dbeaver.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/dbeaver.gpg] https://dbeaver.io/debs/dbeaver-ce /" | sudo tee /etc/apt/sources.list.d/dbeaver.list

# Update and install DBeaver
echo "📥 Installing DBeaver Community Edition..."
sudo apt update
sudo apt install -y dbeaver-ce

echo "🚀 DBeaver installed successfully!"
