#!/usr/bin/env bash

set -euo pipefail

ACTION="install"
GO_VERSION=""
FALLBACK_GO_VERSION="1.24.3"

usage() {
  cat <<'USAGE'
Usage: go.sh [install|upgrade|uninstall] [options]

Actions:
  install    Download and install Go + tools (default)
  upgrade    Remove existing Go installation, install requested/latest version
  uninstall  Remove /usr/local/go and clean PATH entries from ~/.zshrc

Options:
  --version VERSION  Install a specific Go version (e.g. 1.24.3)
  -h, --help         Show this help

Environment:
  DEFAULT_GO_VERSION  Override the default/latest version lookup
USAGE
}

step() {
  printf '\n[%s] %s\n' "$1" "$2"
}

usage_error() {
  printf 'go.sh: %s\n\n' "$1" >&2
  usage >&2
  exit 2
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      install | upgrade | uninstall)
        ACTION="$1"
        ;;
      --version)
        shift
        if [ "$#" -eq 0 ] || [ -z "$1" ]; then
          usage_error "--version requires a value"
        fi
        GO_VERSION="$1"
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

_latest_go_version() {
  curl -fsSL 'https://go.dev/dl/?mode=json' \
    | grep -oP '"version":\s*"go\K[0-9.]+' \
    | head -1
}

resolve_go_version() {
  if [ -n "$GO_VERSION" ]; then
    return
  fi

  local default_version
  default_version="${DEFAULT_GO_VERSION:-}"

  if [ -z "$default_version" ]; then
    step "version" "Looking up latest Go version..."
    default_version="$(_latest_go_version || echo "$FALLBACK_GO_VERSION")"
    if [ -z "$default_version" ]; then
      default_version="$FALLBACK_GO_VERSION"
    fi
  fi

  read -r -p "Enter the version of Go to install (default: ${default_version}): " user_input
  GO_VERSION="${user_input:-$default_version}"
}

uninstall_go() {
  step "uninstall" "Removing /usr/local/go..."
  sudo rm -rf /usr/local/go

  step "uninstall" "Removing Go PATH entries from ~/.zshrc..."
  if [ -f "$HOME/.zshrc" ]; then
    sed -i '/\/usr\/local\/go\/bin/d' "$HOME/.zshrc"
  fi

  step "uninstall" "Done. Restart your shell to clear Go from PATH."
}

install_go() {
  resolve_go_version

  step "install" "Installing Go ${GO_VERSION}..."

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  # Bake path into trap: local tmp_dir is out of scope when EXIT runs (set -u errors).
  trap "rm -rf $(printf '%q' "$tmp_dir")" EXIT

  local archive="go${GO_VERSION}.linux-amd64.tar.gz"
  curl -fsSL "https://go.dev/dl/${archive}" -o "$tmp_dir/${archive}"

  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "$tmp_dir/${archive}"

  if ! grep -q '/usr/local/go/bin' "$HOME/.zshrc" 2>/dev/null; then
    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> "$HOME/.zshrc"
  fi
  export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

  step "verify" "Go version:"
  go version

  local go_bin
  go_bin="$(go env GOPATH)/bin"
  export PATH="$PATH:$go_bin"

  step "tools" "Installing wire, templ, air..."
  go install github.com/google/wire/cmd/wire@latest
  go install github.com/a-h/templ/cmd/templ@latest
  go install github.com/air-verse/air@latest

  step "verify" "Checking tools (warnings are non-fatal)..."
  check_tool "$go_bin/wire" help
  check_tool "$go_bin/templ" version
  check_tool "$go_bin/air" -v

  step "done" "Go ${GO_VERSION} installed. Reload shell or run: source ~/.zshrc"

  rm -rf "$tmp_dir"
  trap - EXIT
}

# Warns if a tool check fails rather than aborting the script or its caller.
check_tool() {
  local bin="$1"; shift
  if "$bin" "$@" >/dev/null 2>&1; then
    echo "  ok: $(basename "$bin")"
  else
    echo "WARN: $(basename "$bin") check failed — it may work after shell reload" >&2
  fi
}

parse_args "$@"

case "$ACTION" in
  install)
    install_go
    ;;
  upgrade)
    step "upgrade" "Upgrading Go: removing old installation first..."
    uninstall_go
    install_go
    ;;
  uninstall)
    uninstall_go
    ;;
  *)
    usage_error "unknown action: $ACTION"
    ;;
esac
