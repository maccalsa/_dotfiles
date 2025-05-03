#!/bin/bash

set -e  # Exit on error

echo "🔍 Checking Nix environment cleanup requirements..."

# Stop the Nix daemon if running (multi-user mode)
if systemctl is-active --quiet nix-daemon; then
    echo "🛑 Stopping Nix daemon..."
    sudo systemctl stop nix-daemon
fi

# Purge all generations and profiles
echo "🗑 Removing old profiles and generations..."
nix profile wipe-history
sudo nix-collect-garbage -d
nix store gc

# Optimize Nix store
echo "🛠 Optimizing Nix store..."
nix store optimise

# Remove orphaned paths from /nix/store
echo "🧹 Cleaning up orphaned paths in /nix/store..."
sudo nix-store --gc

# Remove temporary build paths
echo "🗑 Removing temporary build directories..."
sudo rm -rf /tmp/nix-build-* ~/.cache/nix

# Optional: Reset Nix profiles
# echo "🔄 Resetting user profile..."
# rm -rf ~/.nix-profile
# ln -s /nix/var/nix/profiles/per-user/$USER ~/.nix-profile

# Optional: Fully uninstall Nix (uncomment to enable)
# echo "❌ Uninstalling Nix completely..."
# sudo rm -rf /nix /etc/nix /var/root/.nix-profile ~/.nix-profile ~/.nix-defexpr ~/.nix-channels

echo "✅ Nix cleanup complete!"
echo "🚀 You may want to reboot to fully apply changes: sudo reboot"
