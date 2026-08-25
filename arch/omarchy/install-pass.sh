#!/usr/bin/env bash

set -euo pipefail

echo "🔐 [1/5] Checking pass, GPG and Git..."

required_packages=(
    pass
    gnupg
    git
)

missing_packages=()

for package in "${required_packages[@]}"; do
    if ! pacman -Q "$package" >/dev/null 2>&1; then
        missing_packages+=("$package")
    fi
done

if [ ${#missing_packages[@]} -gt 0 ]; then
    echo "Installing missing packages:"
    printf '  - %s\n' "${missing_packages[@]}"

    sudo pacman -S --needed --noconfirm "${missing_packages[@]}"
else
    echo "✅ Required packages already installed."
fi

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

touch "$GPG_AGENT_CONF"
chmod 600 "$GPG_AGENT_CONF"

grep -qxF "default-cache-ttl 3600" "$GPG_AGENT_CONF" ||
    echo "default-cache-ttl 3600" >> "$GPG_AGENT_CONF"

grep -qxF "max-cache-ttl 86400" "$GPG_AGENT_CONF" ||
    echo "max-cache-ttl 86400" >> "$GPG_AGENT_CONF"

echo "🔁 [4/5] Restarting GPG agent..."

gpgconf --kill gpg-agent 2>/dev/null || true
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
