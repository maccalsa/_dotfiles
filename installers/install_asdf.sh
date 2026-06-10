#!/bin/bash

set -euo pipefail

ACTION="install"
ASDF_VERSION="${ASDF_VERSION:-0.18.1}"
ASDF_INSTALL_DIR="${ASDF_INSTALL_DIR:-$HOME/.local/bin}"

usage() {
  cat <<'USAGE'
Usage: install_asdf.sh [install|upgrade] [options]

Actions:
  install  Install asdf binary (default). Aborts if old shell-sourced asdf is
           detected to prevent breaking existing Erlang/Elixir/mix installs.
  upgrade  Download and replace the asdf binary with the requested version.
           Use this only when you understand the shim layout change between
           shell-sourced (<=0.15) and binary (>=0.16) asdf formats.

Options:
  --version VERSION  asdf version to install (default: 0.18.1)
  -h, --help         Show this help

Environment:
  ASDF_VERSION      asdf release to download (default: 0.18.1)
  ASDF_INSTALL_DIR  Directory to install the binary (default: ~/.local/bin)

WARNING (old-format users):
  If you have the shell-sourced asdf (i.e. ~/.asdf/asdf.sh exists), the new
  binary format uses a different shim directory layout. Upgrading without
  re-installing your plugins and language versions may break `mix`, `elixir`,
  `erlang`, etc. The 'upgrade' action will warn you and ask to confirm.
USAGE
}

usage_error() {
  printf 'install_asdf.sh: %s\n\n' "$1" >&2
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
        ASDF_VERSION="$1"
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

# wxGTK dev package name differs by Ubuntu/Pop release (noble+ uses 3.2).
pkg_is_installable() {
  local pkg="$1"
  local cand
  cand="$(apt-cache policy "$pkg" 2>/dev/null | awk '/^  Candidate:/ {print $2}')"
  [[ -n "$cand" && "$cand" != "(none)" ]]
}

wx_gtk_dev_package() {
  local p candidates=(
    libwxgtk3.2-gtk3-dev
    libwxgtk3.2-dev
    libwxgtk3.0-gtk3-dev
  )
  for p in "${candidates[@]}"; do
    if pkg_is_installable "$p"; then
      echo "$p"
      return 0
    fi
  done
  return 1
}

install_build_deps() {
  echo "🔧 Installing dependencies for asdf..."
  sudo apt update

  WX_DEV="$(wx_gtk_dev_package || true)"
  if [[ -z "${WX_DEV:-}" ]]; then
    echo "WARN: No installable wxGTK dev package found. Erlang/OTP builds may skip or fail wx widgets." >&2
    echo "      On Pop!_/Ubuntu noble, install libwxgtk3.2-gtk3-dev (often needs universe):" >&2
    echo "        sudo add-apt-repository universe && sudo apt update" >&2
    echo "      If you pulled this repo earlier, rerun the latest installers/install_asdf.sh (not an old copy)." >&2
  else
    echo "Using wxGTK dev package: $WX_DEV"
  fi

  # libncurses-dev replaces libncurses5-dev on newer suites; apt satisfies either.
  local PKGS=(
    git curl build-essential autoconf m4
    libncurses-dev
    libssl-dev libsqlite3-dev libreadline-dev zlib1g-dev
  )
  [[ -n "${WX_DEV:-}" ]] && PKGS+=("$WX_DEV")
  sudo apt install -y "${PKGS[@]}"
}

detect_old_format() {
  # The shell-sourced asdf (<= 0.15) uses ~/.asdf/asdf.sh for init and stores
  # shims in ~/.asdf/shims. The new binary (>= 0.16) uses a different layout.
  # Mixing them will silently break any language installed via the old format.
  [ -f "$HOME/.asdf/asdf.sh" ]
}

download_and_install_binary() {
  local arch
  case "$(uname -m)" in
    x86_64)        arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    i386|i686)     arch="386" ;;
    *)
      echo "Unsupported architecture for asdf binary install: $(uname -m)" >&2
      exit 1
      ;;
  esac

  echo "⬇️ Installing asdf ${ASDF_VERSION}..."

  mkdir -p "$ASDF_INSTALL_DIR"
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT

  curl -fsSL \
    "https://github.com/asdf-vm/asdf/releases/download/v${ASDF_VERSION}/asdf-v${ASDF_VERSION}-linux-${arch}.tar.gz" \
    -o "$tmp_dir/asdf.tar.gz"
  tar -xzf "$tmp_dir/asdf.tar.gz" -C "$tmp_dir"
  install -m 0755 "$tmp_dir/asdf" "$ASDF_INSTALL_DIR/asdf"
}

setup_shell_config() {
  local shell_config="${HOME}/.zshrc"
  if ! grep -q 'asdf setup' "$shell_config" 2>/dev/null; then
    {
      echo ''
      echo '# asdf setup'
      echo 'export PATH="$HOME/.local/bin:$HOME/.asdf/shims:$PATH"'
    } >> "$shell_config"
  fi
  export PATH="$HOME/.local/bin:$HOME/.asdf/shims:$PATH"
}

do_install() {
  if detect_old_format; then
    cat >&2 <<'WARN'

⚠️  Old shell-sourced asdf detected (~/.asdf/asdf.sh exists).

The binary asdf format (>= 0.16) uses a different shim directory layout.
Installing over the old format WITHOUT migrating your plugins will break
tools managed by asdf (Erlang, Elixir, mix, etc.).

To proceed anyway, re-run with the 'upgrade' action:
  bash installers/install_asdf.sh upgrade

The upgrade action will warn you again and ask for explicit confirmation.
WARN
    exit 1
  fi

  install_build_deps
  download_and_install_binary
  setup_shell_config

  echo "✅ asdf installed successfully:"
  asdf --version
  echo "Reload your shell or run: source ${HOME}/.zshrc"
}

do_upgrade() {
  if detect_old_format; then
    cat >&2 <<'WARN'

⚠️  Old shell-sourced asdf detected (~/.asdf/asdf.sh exists).

Upgrading to the binary format will change the shim directory layout.
Any language versions you installed via the old asdf (Erlang, Elixir,
Node, Python, etc.) will need their plugins re-added and versions
re-installed after the upgrade.

Recommended steps after upgrading:
  1. Re-install all plugins:   asdf plugin add erlang / elixir / etc.
  2. Re-install versions:      asdf install erlang <version>
  3. Set globals:              asdf set -u erlang <version>

WARN
    read -r -p "Type YES to proceed with the upgrade anyway: " answer
    if [[ "$answer" != "YES" ]]; then
      echo "Aborted."
      exit 1
    fi
  fi

  download_and_install_binary
  setup_shell_config

  echo "✅ asdf upgraded to ${ASDF_VERSION}:"
  asdf --version
  echo "Reload your shell or run: source ${HOME}/.zshrc"
}

parse_args "$@"

case "$ACTION" in
  install)  do_install ;;
  upgrade)  do_upgrade ;;
  *)        usage_error "unknown action: $ACTION" ;;
esac
