#!/usr/bin/env bash

# Install or upgrade Cursor IDE through Cursor's apt repository.
# Matches Cursor's official keyring path to avoid Signed-By conflicts when the
# desktop app or a prior install already registered the repo.

set -euo pipefail

ACTION="install"

CURSOR_APT_KEY_URL="https://downloads.cursor.com/keys/anysphere.asc"
CURSOR_APT_REPO="https://downloads.cursor.com/aptrepo"
# Official Cursor installer uses this keyring (not /etc/apt/keyrings/cursor.gpg).
CURSOR_APT_KEYRING="/usr/share/keyrings/anysphere.gpg"
CURSOR_APT_LIST="/etc/apt/sources.list.d/cursor.list"
# Legacy path from an earlier version of this script — remove if present.
CURSOR_LEGACY_KEYRING="/etc/apt/keyrings/cursor.gpg"
LEGACY_APPIMAGE_PATH="/opt/cursor.AppImage"
LEGACY_DESKTOP_ENTRY="/usr/share/applications/cursor.desktop"

usage() {
  cat <<'USAGE'
Usage: install_cursor.sh [install|upgrade]

Actions:
  install  Set up the Cursor apt repository and install Cursor (default)
  upgrade  Upgrade Cursor in-place via apt (repo must already be configured)

  -h, --help  Show this help
USAGE
}

usage_error() {
  printf 'install_cursor.sh: %s\n\n' "$1" >&2
  usage >&2
  exit 2
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      install | upgrade)
        ACTION="$1"
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

cursor_apt_source_files() {
  grep -rl 'downloads\.cursor\.com' /etc/apt/sources.list.d/ 2>/dev/null || true
}

cursor_repo_configured() {
  [[ -n "$(cursor_apt_source_files)" ]]
}

# Apt errors when the same repo URL has different signed-by= paths in multiple files.
remove_conflicting_cursor_apt_config() {
  local files other
  files="$(cursor_apt_source_files)"

  if [[ -z "$files" ]]; then
    return 0
  fi

  # Drop legacy keyring from an older run of this script.
  if [[ -f "$CURSOR_LEGACY_KEYRING" ]]; then
    echo "🧹 Removing legacy Cursor keyring ($CURSOR_LEGACY_KEYRING)..."
    sudo rm -f "$CURSOR_LEGACY_KEYRING"
  fi

  # If our cursor.list duplicates another Cursor source entry, remove only ours.
  if [[ -f "$CURSOR_APT_LIST" ]]; then
    if grep -q '/etc/apt/keyrings/cursor.gpg' "$CURSOR_APT_LIST" 2>/dev/null; then
      echo "🧹 Removing legacy Cursor apt source (wrong keyring path)..."
      sudo rm -f "$CURSOR_APT_LIST"
    else
      other="$(printf '%s\n' "$files" | grep -v "^${CURSOR_APT_LIST}$" || true)"
      if [[ -n "$other" ]]; then
        echo "🧹 Removing duplicate Cursor apt source ($(basename "$CURSOR_APT_LIST"))..."
        sudo rm -f "$CURSOR_APT_LIST"
      fi
    fi
  fi
}

ensure_cursor_apt_repo() {
  remove_conflicting_cursor_apt_config

  if cursor_repo_configured; then
    echo "📝 Cursor apt repository already configured."
    return 0
  fi

  echo "🔐 Installing Cursor apt signing key..."
  sudo install -d -m 0755 /usr/share/keyrings
  curl -fsSL "$CURSOR_APT_KEY_URL" | gpg --dearmor | sudo tee "$CURSOR_APT_KEYRING" >/dev/null
  sudo chmod 0644 "$CURSOR_APT_KEYRING"

  echo "📝 Registering Cursor apt repository..."
  echo "deb [arch=amd64,arm64 signed-by=${CURSOR_APT_KEYRING}] ${CURSOR_APT_REPO} stable main" |
    sudo tee "$CURSOR_APT_LIST" >/dev/null
}

remove_legacy_appimage() {
  if [ -L /usr/local/bin/cursor ] && [ "$(readlink /usr/local/bin/cursor)" = "$LEGACY_APPIMAGE_PATH" ]; then
    echo "🧹 Removing old AppImage cursor symlink..."
    sudo rm -f /usr/local/bin/cursor
  fi

  if [ -f "$LEGACY_APPIMAGE_PATH" ]; then
    echo "🧹 Removing old Cursor AppImage..."
    sudo rm -f "$LEGACY_APPIMAGE_PATH"
  fi

  if [ -f "$LEGACY_DESKTOP_ENTRY" ] && grep -q "$LEGACY_APPIMAGE_PATH" "$LEGACY_DESKTOP_ENTRY"; then
    echo "🧹 Removing old AppImage desktop entry..."
    sudo rm -f "$LEGACY_DESKTOP_ENTRY"
  fi
}

do_install() {
  echo "📦 Installing dependencies for Cursor apt repository..."
  sudo apt update
  sudo apt install -y ca-certificates curl gpg

  ensure_cursor_apt_repo

  echo "⬇️  Installing Cursor..."
  sudo apt-get update
  sudo apt install -y cursor

  remove_legacy_appimage

  echo "✅ Cursor installed."
  echo "   GUI: application menu → Cursor"
  echo "   Terminal: cursor ."
}

do_upgrade() {
  remove_conflicting_cursor_apt_config

  if ! cursor_repo_configured; then
    echo "Cursor apt repository not configured — running full install instead." >&2
    do_install
    return
  fi

  echo "⬇️  Upgrading Cursor (apt)..."
  sudo apt-get update
  sudo apt-get install -y --only-upgrade cursor

  remove_legacy_appimage

  echo "✅ Cursor upgraded."
  cursor --version 2>/dev/null || true
}

parse_args "$@"

case "$ACTION" in
  install)  do_install ;;
  upgrade)  do_upgrade ;;
  *)        usage_error "unknown action: $ACTION" ;;
esac
