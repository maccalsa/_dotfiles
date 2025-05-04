#!/bin/bash

set -e

BACKUP_FILE="secret-backup-$(date +%Y-%m-%d).tar.gpg"

echo "Creating encrypted backup of SSH and GPG keys..."

tar czf - ~/.ssh ~/.gnupg | gpg --symmetric --cipher-algo AES256 -o "$BACKUP_FILE"

echo "Backup complete: $BACKUP_FILE"
echo "Store this file safely!"
