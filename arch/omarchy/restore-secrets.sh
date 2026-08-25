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

#
# Dependencies
#

echo "📦 Checking required tools..."

required_packages=(
    gnupg
    openssh
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

#
# Restore
#

echo
echo "🔐 Restoring SSH and GPG keys..."

# Stop the GPG agent before replacing ~/.gnupg contents.
gpgconf --kill gpg-agent 2>/dev/null || true

# Decrypt and extract the backup.
#
# pipefail ensures that a failed GPG decrypt or failed tar extraction
# causes the script to stop.
gpg --decrypt "$BACKUP_FILE" | tar xz -C "$HOME"

#
# SSH permissions
#

echo
echo "🔒 Fixing permissions..."

if [ -d "$HOME/.ssh" ]; then
    chmod 700 "$HOME/.ssh"

    # Default all SSH files to private.
    find "$HOME/.ssh" \
        -maxdepth 1 \
        -type f \
        -exec chmod 600 {} \;

    # Public keys can be world-readable.
    find "$HOME/.ssh" \
        -maxdepth 1 \
        -type f \
        -name '*.pub' \
        -exec chmod 644 {} \;

    # known_hosts does not contain secrets.
    [ -f "$HOME/.ssh/known_hosts" ] &&
        chmod 644 "$HOME/.ssh/known_hosts"
fi

#
# GPG permissions
#

if [ -d "$HOME/.gnupg" ]; then
    # GnuPG expects its directory tree to be private.
    find "$HOME/.gnupg" \
        -type d \
        -exec chmod 700 {} \;

    find "$HOME/.gnupg" \
        -type f \
        -exec chmod 600 {} \;
fi

#
# Restart GPG
#

echo
echo "🔁 Restarting GPG agent..."

gpgconf --launch gpg-agent

#
# Verification
#

echo
echo "✅ Restoration complete."

echo
echo "GPG secret keys:"
gpg --list-secret-keys --keyid-format LONG || true

echo
echo "SSH public keys:"

if [ -d "$HOME/.ssh" ]; then
    find "$HOME/.ssh" \
        -maxdepth 1 \
        -type f \
        -name '*.pub' \
        -print 2>/dev/null || true
fi

echo
echo "Test GitHub SSH authentication with:"
echo "    ssh -T git@github.com"

echo
echo "System updates remain managed by Omarchy:"
echo "    omarchy update"
