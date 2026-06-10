#!/bin/bash

set -euo pipefail

ACTION="install"
PHX_VERSION=""
DEFAULT_PHX_VERSION="${PHX_VERSION:-1.8.5}"

usage() {
  cat <<'USAGE'
Usage: phoenix.sh [install|upgrade] [options]

Actions:
  install  Install the Phoenix archive for the specified version (default)
  upgrade  Install the latest published Phoenix archive (phx_new)

Options:
  --version VERSION  Phoenix version to install (e.g. 1.8.5)
  --latest           Resolve and install the latest hex.pm release
  -h, --help         Show this help

Environment:
  PHX_VERSION  Override default Phoenix version
USAGE
}

usage_error() {
  printf 'phoenix.sh: %s\n\n' "$1" >&2
  usage >&2
  exit 2
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      install | upgrade)
        ACTION="$1"
        ;;
      --version)
        shift
        [ "$#" -gt 0 ] || usage_error "--version requires a value"
        PHX_VERSION="$1"
        ;;
      --latest)
        PHX_VERSION="latest"
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

ensure_mix() {
  if ! command -v mix >/dev/null 2>&1; then
    export PATH="$HOME/.local/bin:$HOME/.asdf/shims:$PATH"
  fi

  if ! command -v mix >/dev/null 2>&1 && [ -f "$HOME/.asdf/asdf.sh" ]; then
    # shellcheck disable=SC1091
    . "$HOME/.asdf/asdf.sh"
  fi

  if ! command -v mix >/dev/null 2>&1; then
    echo "mix is required before installing Phoenix. Install Elixir first." >&2
    exit 1
  fi
}

install_phoenix() {
  local version="$1"
  if [ "$version" = "latest" ]; then
    echo "🚀 Installing latest Phoenix generator..."
    mix archive.install hex phx_new --force
  else
    echo "🚀 Installing Phoenix ${version} generator..."
    mix archive.install hex phx_new "$version" --force
  fi
}

do_install() {
  ensure_mix
  local version="${PHX_VERSION:-$DEFAULT_PHX_VERSION}"
  install_phoenix "$version"
}

do_upgrade() {
  ensure_mix
  # For upgrade, default to latest unless a specific version was given.
  local version="${PHX_VERSION:-latest}"
  install_phoenix "$version"
}

parse_args "$@"

case "$ACTION" in
  install)  do_install ;;
  upgrade)  do_upgrade ;;
  *)        usage_error "unknown action: $ACTION" ;;
esac
