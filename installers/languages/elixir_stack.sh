#!/bin/bash

set -euo pipefail

ACTION="install"
DEFAULT_ERLANG_MAJOR="${DEFAULT_ERLANG_MAJOR:-27}"
DEFAULT_ELIXIR_VERSION="${DEFAULT_ELIXIR_VERSION:-1.18.4-otp-27}"

ERLANG_VERSION="${ERLANG_VERSION:-}"
ELIXIR_VERSION="${ELIXIR_VERSION:-$DEFAULT_ELIXIR_VERSION}"

usage() {
  cat <<'USAGE'
Usage: elixir_stack.sh [install|upgrade] [options]

Actions:
  install  Install Erlang and Elixir via asdf (default)
  upgrade  Install latest Erlang (for the configured major) and the requested
           Elixir version, then set both as the asdf global default

Options:
  --erlang-major MAJOR    Erlang major version to resolve latest for (default: 27)
  --erlang-version VER    Exact Erlang version to install (skips auto-resolve)
  --elixir-version VER    Elixir version to install (default: 1.18.4-otp-27)
  -h, --help              Show this help

Environment:
  DEFAULT_ERLANG_MAJOR    Erlang major to auto-resolve (default: 27)
  DEFAULT_ELIXIR_VERSION  Elixir version fallback (default: 1.18.4-otp-27)
  ERLANG_VERSION          Override Erlang version
  ELIXIR_VERSION          Override Elixir version
USAGE
}

usage_error() {
  printf 'elixir_stack.sh: %s\n\n' "$1" >&2
  usage >&2
  exit 2
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      install | upgrade)
        ACTION="$1"
        ;;
      --erlang-major)
        shift
        [ "$#" -gt 0 ] || usage_error "--erlang-major requires a value"
        DEFAULT_ERLANG_MAJOR="$1"
        ;;
      --erlang-version)
        shift
        [ "$#" -gt 0 ] || usage_error "--erlang-version requires a value"
        ERLANG_VERSION="$1"
        ;;
      --elixir-version)
        shift
        [ "$#" -gt 0 ] || usage_error "--elixir-version requires a value"
        ELIXIR_VERSION="$1"
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

ensure_asdf() {
  if ! command -v asdf >/dev/null 2>&1; then
    export PATH="$HOME/.local/bin:$HOME/.asdf/shims:$PATH"
  fi

  if ! command -v asdf >/dev/null 2>&1; then
    if [ -f "$HOME/.asdf/asdf.sh" ]; then
      # shellcheck disable=SC1091
      . "$HOME/.asdf/asdf.sh"
    else
      echo "asdf is required before installing Erlang and Elixir." >&2
      exit 1
    fi
  fi
}

asdf_set_user_version() {
  local tool="$1"
  local version="$2"

  if asdf help 2>/dev/null | grep -q '^asdf set '; then
    asdf set -u "$tool" "$version"
  else
    asdf global "$tool" "$version"
  fi
}

install_versions() {
  echo "📦 Installing Erlang ${ERLANG_VERSION} & Elixir ${ELIXIR_VERSION} using asdf..."

  asdf install erlang "$ERLANG_VERSION"
  asdf_set_user_version erlang "$ERLANG_VERSION"

  asdf install elixir "$ELIXIR_VERSION"
  asdf_set_user_version elixir "$ELIXIR_VERSION"

  echo "🔧 Installing Hex & Rebar..."
  mix local.hex --force
  mix local.rebar --force

  echo "✅ Elixir (${ELIXIR_VERSION}), Erlang (${ERLANG_VERSION}), Hex & Rebar installed."
}

do_install() {
  ensure_asdf

  echo "📦 Installing Erlang & Elixir using asdf..."

  asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git || true
  asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git || true

  asdf plugin update erlang || true
  asdf plugin update elixir || true

  if [ -z "$ERLANG_VERSION" ]; then
    ERLANG_VERSION="$(asdf latest erlang "$DEFAULT_ERLANG_MAJOR")"
  fi

  install_versions
}

do_upgrade() {
  ensure_asdf

  echo "🔄 Updating asdf plugins..."
  asdf plugin update erlang || true
  asdf plugin update elixir || true

  if [ -z "$ERLANG_VERSION" ]; then
    ERLANG_VERSION="$(asdf latest erlang "$DEFAULT_ERLANG_MAJOR")"
    echo "Resolved latest Erlang ${DEFAULT_ERLANG_MAJOR}.x: ${ERLANG_VERSION}"
  fi

  install_versions
}

parse_args "$@"

case "$ACTION" in
  install)  do_install ;;
  upgrade)  do_upgrade ;;
  *)        usage_error "unknown action: $ACTION" ;;
esac
