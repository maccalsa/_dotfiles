#!/bin/bash

set -euo pipefail

ACTION="install"
RUST_TOOLCHAIN=""
DEFAULT_RUST_TOOLCHAIN="stable"

usage() {
  cat <<'USAGE'
Usage: rust.sh [install|upgrade] [options]

Actions:
  install  Install rustup and the requested Rust toolchain (default)
  upgrade  Update all installed toolchains via rustup

Options:
  --toolchain TOOLCHAIN  Toolchain to install/set default (e.g. stable, nightly, 1.78.0)
  -h, --help             Show this help
USAGE
}

usage_error() {
  printf 'rust.sh: %s\n\n' "$1" >&2
  usage >&2
  exit 2
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      install | upgrade)
        ACTION="$1"
        ;;
      --toolchain)
        shift
        if [ "$#" -eq 0 ] || [ -z "$1" ]; then
          usage_error "--toolchain requires a value"
        fi
        RUST_TOOLCHAIN="$1"
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        usage_error "unknown argument: $1"
        ;;
    esac
    shift
  done
}

load_cargo() {
  if [ -f "$HOME/.cargo/env" ]; then
    # shellcheck disable=SC1091
    . "$HOME/.cargo/env"
  fi
}

resolve_toolchain() {
  if [ -n "$RUST_TOOLCHAIN" ]; then
    return
  fi
  read -r -p "Enter the Rust toolchain to install (default: ${DEFAULT_RUST_TOOLCHAIN}): " user_input
  RUST_TOOLCHAIN="${user_input:-$DEFAULT_RUST_TOOLCHAIN}"
}

do_install() {
  resolve_toolchain

  if ! command -v rustup >/dev/null 2>&1; then
    echo "Installing rustup and Rust ${RUST_TOOLCHAIN}..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain "$RUST_TOOLCHAIN"
  else
    echo "rustup already installed — installing toolchain ${RUST_TOOLCHAIN}..."
    rustup toolchain install "$RUST_TOOLCHAIN"
    rustup default "$RUST_TOOLCHAIN"
  fi

  load_cargo
  rustup component add rustfmt clippy rust-analyzer

  echo "Rust installation complete:"
  rustc --version
  cargo --version
}

do_upgrade() {
  load_cargo

  if ! command -v rustup >/dev/null 2>&1; then
    echo "rustup not found — run install first." >&2
    exit 1
  fi

  echo "Updating all Rust toolchains..."
  rustup update

  # If a specific toolchain was requested, make it the default.
  if [ -n "$RUST_TOOLCHAIN" ]; then
    rustup default "$RUST_TOOLCHAIN"
  fi

  rustup component add rustfmt clippy rust-analyzer

  echo "Rust upgrade complete:"
  rustc --version
  cargo --version
}

parse_args "$@"

case "$ACTION" in
  install)  do_install ;;
  upgrade)  do_upgrade ;;
  *)        usage_error "unknown action: $ACTION" ;;
esac
