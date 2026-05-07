#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing Unity Hub on Pop!_OS"

sudo apt update

echo "==> Installing dependencies"
sudo apt install -y \
  curl \
  gpg \
  ca-certificates \
  wget \
  libgtk-3-0 \
  libnss3 \
  libxss1 \
  libasound2t64 \
  libgbm1 \
  libglu1-mesa \
  mesa-utils

echo "==> Adding Unity Hub signing key"
sudo install -d -m 0755 /etc/apt/keyrings

curl -fsSL https://hub.unity3d.com/linux/keys/public \
  | sudo gpg --dearmor -o /etc/apt/keyrings/unityhub.gpg

sudo chmod 0644 /etc/apt/keyrings/unityhub.gpg

echo "==> Adding Unity Hub apt repo"
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/unityhub.gpg] https://hub.unity3d.com/linux/repos/deb stable main" \
  | sudo tee /etc/apt/sources.list.d/unityhub.list > /dev/null

echo "==> Installing Unity Hub"
sudo apt update
sudo apt install -y unityhub

echo "==> Checking graphics"
glxinfo | grep -E "OpenGL renderer|OpenGL version" || true

echo
echo "Done."
echo "Launch Unity Hub with:"
echo "  unityhub"
echo
echo "In Unity Hub:"
echo "  1. Sign in"
echo "  2. Installs -> Install Editor"
echo "  3. Choose latest LTS"
echo "  4. Add Linux Build Support"
echo "  5. Use URP for first 3D projects, not HDRP"
