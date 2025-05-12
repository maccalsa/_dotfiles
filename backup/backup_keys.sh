#!/bin/bash

set -e

BACKUP_FILE="secret-backup-$(date +%Y-%m-%d).tar.gpg"

echo "Creating encrypted backup of SSH and GPG keys..."

cd "$HOME"
tar czf - .ssh .gnupg | gpg --symmetric --cipher-algo AES256 -o "$BACKUP_FILE"

echo "Backup contains:"
gpg --decrypt "$BACKUP_FILE" | tar tz

echo "Backup complete: $BACKUP_FILE"
echo "Store this file safely!"
