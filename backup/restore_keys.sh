#!/bin/bash

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <backup-file.tar.gpg>"
  exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Backup file not found: $BACKUP_FILE"
  exit 1
fi

echo "Restoring SSH and GPG keys from encrypted backup..."

gpg --decrypt "$BACKUP_FILE" | tar xz -C ~

chmod 700 ~/.ssh ~/.gnupg
chmod 600 ~/.ssh/id_* ~/.gnupg/private-keys-v1.d/*

echo "Restoration complete! Verify your keys with:"
echo "  ssh-add -l"
echo "  gpg --list-secret-keys"

echo "Done!"