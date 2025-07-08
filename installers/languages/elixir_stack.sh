#!/bin/bash

set -e

ERLANG_VERSION="26.2.4"
ELIXIR_VERSION="1.16.2-otp-26"

echo "📦 Installing Erlang & Elixir using asdf..."

asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git || true
asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git || true

asdf install erlang "$ERLANG_VERSION"
asdf global erlang "$ERLANG_VERSION"

asdf install elixir "$ELIXIR_VERSION"
asdf global elixir "$ELIXIR_VERSION"

echo "🔧 Installing Hex & Rebar..."

mix local.hex --force
mix local.rebar --force

echo "✅ Elixir ($ELIXIR_VERSION), Erlang ($ERLANG_VERSION), Hex & Rebar installed successfully!"

