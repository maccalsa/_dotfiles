#!/bin/bash

set -euo pipefail

DEFAULT_RUST_TOOLCHAIN="stable"

read -r -p "Enter the Rust toolchain to install (default: ${DEFAULT_RUST_TOOLCHAIN}): " RUST_TOOLCHAIN
RUST_TOOLCHAIN=${RUST_TOOLCHAIN:-$DEFAULT_RUST_TOOLCHAIN}

if ! command -v rustup >/dev/null 2>&1; then
  echo "Installing rustup and Rust ${RUST_TOOLCHAIN}..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain "$RUST_TOOLCHAIN"
else
  echo "rustup already installed."
  rustup toolchain install "$RUST_TOOLCHAIN"
  rustup default "$RUST_TOOLCHAIN"
fi

if [ -f "$HOME/.cargo/env" ]; then
  # shellcheck disable=SC1091
  . "$HOME/.cargo/env"
fi

rustup component add rustfmt clippy rust-analyzer

echo "Rust installation complete:"
rustc --version
cargo --version
