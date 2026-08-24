#!/usr/bin/env bash

set -euo pipefail

BACKUP_FILE="${1:-secret-backup-$(date +%Y-%m-%d).tar.gpg}"

echo "🔐 Creating encrypted backup of SSH and GPG keys..."

cd "$HOME"

for dir in .ssh .gnupg; do
    if [ ! -d "$dir" ]; then
        echo "⚠️ $HOME/$dir does not exist."
        exit 1
    fi
done

tar czf - .ssh .gnupg |
    gpg --symmetric \
        --cipher-algo AES256 \
        --output "$BACKUP_FILE"

echo
echo "📦 Verifying backup contents..."

gpg --decrypt "$BACKUP_FILE" | tar tz

echo
echo "✅ Backup complete:"
echo "   $HOME/$BACKUP_FILE"
echo
echo "⚠️ Store this file somewhere safe."