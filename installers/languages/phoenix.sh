#!/bin/bash

set -euo pipefail

PHX_VERSION="${PHX_VERSION:-1.8.5}"

if ! command -v mix >/dev/null 2>&1; then
  export PATH="$HOME/.local/bin:$HOME/.asdf/shims:$PATH"
fi

if ! command -v mix >/dev/null 2>&1 && [ -f "$HOME/.asdf/asdf.sh" ]; then
  # shellcheck disable=SC1091
  . "$HOME/.asdf/asdf.sh"
fi

if ! command -v mix >/dev/null 2>&1; then
  echo "mix is required before installing Phoenix. Install Elixir first."
  exit 1
fi

echo "🚀 Installing Phoenix $PHX_VERSION generator..."
mix archive.install hex phx_new "$PHX_VERSION" --force


