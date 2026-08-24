#!/usr/bin/env bash

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <backup-file.tar.gpg>"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "📦 Installing required tools..."

sudo pacman -Syu --needed --noconfirm gnupg openssh

echo
echo "🔐 Restoring SSH and GPG keys..."

# Stop GPG before replacing ~/.gnupg contents.
gpgconf --kill gpg-agent 2>/dev/null || true

gpg --decrypt "$BACKUP_FILE" | tar xz -C "$HOME"

echo
echo "🔒 Fixing permissions..."

if [ -d "$HOME/.ssh" ]; then
    chmod 700 "$HOME/.ssh"

    # Private SSH keys
    find "$HOME/.ssh" \
        -maxdepth 1 \
        -type f \
        -name 'id_*' \
        ! -name '*.pub' \
        -exec chmod 600 {} \;

    # Public keys
    find "$HOME/.ssh" \
        -maxdepth 1 \
        -type f \
        -name '*.pub' \
        -exec chmod 644 {} \;

    [ -f "$HOME/.ssh/config" ] &&
        chmod 600 "$HOME/.ssh/config"

    [ -f "$HOME/.ssh/authorized_keys" ] &&
        chmod 600 "$HOME/.ssh/authorized_keys"

    [ -f "$HOME/.ssh/known_hosts" ] &&
        chmod 644 "$HOME/.ssh/known_hosts"
fi

if [ -d "$HOME/.gnupg" ]; then
    chmod 700 "$HOME/.gnupg"

    find "$HOME/.gnupg" \
        -type d \
        -exec chmod 700 {} \;

    if [ -d "$HOME/.gnupg/private-keys-v1.d" ]; then
        find "$HOME/.gnupg/private-keys-v1.d" \
            -type f \
            -exec chmod 600 {} \;
    fi
fi

echo
echo "🔁 Restarting GPG agent..."

gpgconf --launch gpg-agent

echo
echo "✅ Restoration complete."

echo
echo "GPG secret keys:"
gpg --list-secret-keys --keyid-format LONG || true

echo
echo "SSH public keys:"
find "$HOME/.ssh" \
    -maxdepth 1 \
    -name '*.pub' \
    -print 2>/dev/null || true

echo
echo "Test GitHub SSH authentication with:"
echo "    ssh -T git@github.com"