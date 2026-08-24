#!/usr/bin/env bash

set -euo pipefail

echo "🔐 [1/5] Installing pass, GPG and Git..."
sudo pacman -Syu --needed --noconfirm pass gnupg git

echo "🗂️ [2/5] Cloning password store..."
if [ ! -d "$HOME/.password-store/.git" ]; then
    git clone git@github.com:maccalsa/pws-store.git "$HOME/.password-store"
else
    echo "✅ Password store already cloned."
fi

echo "🧠 [3/5] Setting up GPG agent caching..."

GNUPG_DIR="$HOME/.gnupg"
GPG_AGENT_CONF="$GNUPG_DIR/gpg-agent.conf"

mkdir -p "$GNUPG_DIR"
chmod 700 "$GNUPG_DIR"

grep -qxF "default-cache-ttl 3600" "$GPG_AGENT_CONF" 2>/dev/null ||
    echo "default-cache-ttl 3600" >> "$GPG_AGENT_CONF"

grep -qxF "max-cache-ttl 86400" "$GPG_AGENT_CONF" 2>/dev/null ||
    echo "max-cache-ttl 86400" >> "$GPG_AGENT_CONF"

echo "🔁 [4/5] Restarting GPG agent..."
gpgconf --kill gpg-agent
gpgconf --launch gpg-agent

echo "✅ [5/5] Testing password store..."
if pass ls; then
    echo "✅ pass is working."
else
    echo
    echo "⚠️ pass could not open the password store."
    echo "Check your GPG secret key with:"
    echo "    gpg --list-secret-keys --keyid-format LONG"
    echo
    echo "Only run 'pass init <GPG-ID>' if you are creating a NEW password store."
fi