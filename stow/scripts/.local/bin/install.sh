#!/bin/bash

# NextJS Bootstrap Installer
# Installs the nextjs-bootstrap.sh script to ~/.local/bin for global access

set -e

echo "🚀 Installing NextJS Bootstrap Wizard..."

# Check if the script exists
if [[ ! -f "nextjs-bootstrap.sh" ]]; then
    echo "❌ Error: nextjs-bootstrap.sh not found in current directory"
    echo "Please run this installer from the directory containing nextjs-bootstrap.sh"
    exit 1
fi

# Create ~/.local/bin if it doesn't exist
if [[ ! -d "$HOME/.local/bin" ]]; then
    echo "📁 Creating ~/.local/bin directory..."
    mkdir -p "$HOME/.local/bin"
fi

# Copy the script
echo "📦 Copying nextjs-bootstrap.sh to ~/.local/bin/nextjs-bootstrap..."
cp nextjs-bootstrap.sh "$HOME/.local/bin/nextjs-bootstrap"

# Make it executable
echo "🔧 Setting execute permissions..."
chmod +x "$HOME/.local/bin/nextjs-bootstrap"

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo "⚠️  Warning: ~/.local/bin is not in your PATH"
    echo "Add this line to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
    echo "Then restart your terminal or run: source ~/.bashrc"
else
    echo "✅ ~/.local/bin is already in your PATH"
fi

echo ""
echo "🎉 NextJS Bootstrap Wizard installed successfully!"
echo ""
echo "You can now use the command from anywhere:"
echo "  nextjs-bootstrap"
echo ""
echo "Try it out:"
echo "  nextjs-bootstrap"