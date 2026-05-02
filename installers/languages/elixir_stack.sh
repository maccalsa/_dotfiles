#!/bin/bash

set -euo pipefail

DEFAULT_ERLANG_MAJOR="${DEFAULT_ERLANG_MAJOR:-27}"
DEFAULT_ELIXIR_VERSION="${DEFAULT_ELIXIR_VERSION:-1.18.4-otp-27}"

ERLANG_VERSION="${ERLANG_VERSION:-}"
ELIXIR_VERSION="${ELIXIR_VERSION:-$DEFAULT_ELIXIR_VERSION}"

if ! command -v asdf >/dev/null 2>&1; then
  export PATH="$HOME/.local/bin:$HOME/.asdf/shims:$PATH"
fi

if ! command -v asdf >/dev/null 2>&1; then
  if [ -f "$HOME/.asdf/asdf.sh" ]; then
    # shellcheck disable=SC1091
    . "$HOME/.asdf/asdf.sh"
  else
    echo "asdf is required before installing Erlang and Elixir."
    exit 1
  fi
fi

echo "📦 Installing Erlang & Elixir using asdf..."

asdf_set_user_version() {
  local tool="$1"
  local version="$2"

  if asdf help 2>/dev/null | grep -q '^asdf set '; then
    asdf set -u "$tool" "$version"
  else
    asdf global "$tool" "$version"
  fi
}

asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git || true
asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git || true

asdf plugin update erlang || true
asdf plugin update elixir || true

if [ -z "$ERLANG_VERSION" ]; then
  ERLANG_VERSION="$(asdf latest erlang "$DEFAULT_ERLANG_MAJOR")"
fi

asdf install erlang "$ERLANG_VERSION"
asdf_set_user_version erlang "$ERLANG_VERSION"

asdf install elixir "$ELIXIR_VERSION"
asdf_set_user_version elixir "$ELIXIR_VERSION"

echo "🔧 Installing Hex & Rebar..."

mix local.hex --force
mix local.rebar --force

echo "✅ Elixir ($ELIXIR_VERSION), Erlang ($ERLANG_VERSION), Hex & Rebar installed successfully!"

