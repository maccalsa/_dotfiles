#!/usr/bin/env bash

set -euo pipefail

DEFAULT_GO_VERSION="${DEFAULT_GO_VERSION:-1.26.1}"

# What version of go? ask user if none supplied use GO_VERSION
read -r -p "Enter the version of go you want to install (default: $DEFAULT_GO_VERSION): " GO_VERSION
if [ -z "$GO_VERSION" ]; then
  GO_VERSION=$DEFAULT_GO_VERSION
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

archive="go${GO_VERSION}.linux-amd64.tar.gz"
curl -fsSL "https://go.dev/dl/${archive}" -o "$tmp_dir/${archive}"

sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "$tmp_dir/${archive}"

# Add to PATH (you can add this in ~/.zshrc too)
if ! grep -q '/usr/local/go/bin' "$HOME/.zshrc" 2>/dev/null; then
  echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> "$HOME/.zshrc"
fi
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

# Make sure Go is working
go version

# Wire (from Google)
go install github.com/google/wire/cmd/wire@latest

# Templ (fast templating engine)
go install github.com/a-h/templ/cmd/templ@latest

# Air (live-reload for Go projects)
go install github.com/air-verse/air@latest

wire help
templ version
air --version
