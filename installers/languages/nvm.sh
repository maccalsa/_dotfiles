#!/usr/bin/env bash

set -euo pipefail

ACTION="install"
NODE_VERSION=""
NVM_VERSION="${NVM_VERSION:-0.40.4}"
DEFAULT_NODE_VERSION="${DEFAULT_NODE_VERSION:-lts/*}"

usage() {
  cat <<'USAGE'
Usage: nvm.sh [install|upgrade] [options]

Actions:
  install  Install NVM and the requested Node.js version (default)
  upgrade  Install a new Node.js version and set it as default

Options:
  --version VERSION  Node version to install/upgrade to (e.g. 22, lts/*, latest)
  -h, --help         Show this help

Environment:
  DEFAULT_NODE_VERSION  Default Node version (default: lts/*)
  NVM_VERSION           NVM release to install (default: 0.40.4)
USAGE
}

usage_error() {
  printf 'nvm.sh: %s\n\n' "$1" >&2
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
        if [ "$#" -eq 0 ] || [ -z "$1" ]; then
          usage_error "--version requires a value"
        fi
        NODE_VERSION="$1"
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

load_nvm() {
  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
}

resolve_node_version() {
  if [ -n "$NODE_VERSION" ]; then
    return
  fi
  read -r -p "Enter the Node.js version to install (default: ${DEFAULT_NODE_VERSION}): " user_input
  NODE_VERSION="${user_input:-$DEFAULT_NODE_VERSION}"
}

do_install() {
  resolve_node_version

  echo "Installing NVM ${NVM_VERSION}..."
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash

  load_nvm

  echo "Installing Node.js ${NODE_VERSION}..."
  nvm install "$NODE_VERSION"
  nvm use "$NODE_VERSION"
  nvm alias default "$NODE_VERSION"

  echo "Node.js $(node --version) installed and set as default."
}

do_upgrade() {
  resolve_node_version

  load_nvm

  if ! command -v nvm >/dev/null 2>&1; then
    echo "nvm not found — run install first." >&2
    exit 1
  fi

  echo "Installing Node.js ${NODE_VERSION}..."
  nvm install "$NODE_VERSION"
  nvm use "$NODE_VERSION"
  nvm alias default "$NODE_VERSION"

  echo "Default Node.js updated to $(node --version)."
}

parse_args "$@"

case "$ACTION" in
  install)  do_install ;;
  upgrade)  do_upgrade ;;
  *)        usage_error "unknown action: $ACTION" ;;
esac
