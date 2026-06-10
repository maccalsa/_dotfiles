#!/usr/bin/env bash
set -euo pipefail

# Install, upgrade, or check IntelliJ IDEA Ultimate.

ACTION="install"
AUTO_YES=false

JETBRAINS_RELEASES_URL="https://data.services.jetbrains.com/products/releases?code=IIU&latest=true&type=release"
INSTALL_DIR="/opt/idea-IU"
BIN_DIR="/usr/local/bin"
DESKTOP_ENTRY="/usr/share/applications/jetbrains-idea-ultimate.desktop"

usage() {
  cat <<'USAGE'
Usage: install_intellij.sh [install|upgrade|status] [options]

Actions:
  install   Install the latest IntelliJ IDEA Ultimate release (default)
  upgrade   Upgrade only when JetBrains has a newer release
  status    Show installed/latest versions; exits 10 when an upgrade is available

Options:
  -y, --yes   Do not prompt before upgrading
  -h, --help  Show this help
USAGE
}

usage_error() {
  printf 'install_intellij.sh: %s\n\n' "$1" >&2
  usage >&2
  exit 2
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      install | upgrade | status)
        ACTION="$1"
        ;;
      -y | --yes)
        AUTO_YES=true
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

ensure_dependencies() {
  sudo apt update
  sudo apt install -y curl jq wget
}

require_status_dependencies() {
  local missing=()

  command -v curl >/dev/null 2>&1 || missing+=(curl)
  command -v jq >/dev/null 2>&1 || missing+=(jq)

  if [ "${#missing[@]}" -gt 0 ]; then
    printf 'Missing required command(s): %s\n' "${missing[*]}" >&2
    printf 'Run install first or install them with: sudo apt install %s\n' "${missing[*]}" >&2
    exit 3
  fi
}

latest_release_json() {
  curl -fsSL -A "dotfiles-installers/1.0" "$JETBRAINS_RELEASES_URL"
}

latest_field() {
  local field="$1"
  jq -r ".IIU[0]${field}"
}

product_info_file() {
  printf '%s/product-info.json\n' "$INSTALL_DIR"
}

installed_build() {
  local info
  info="$(product_info_file)"
  if [ -f "$info" ]; then
    jq -r '.buildNumber // empty' "$info" 2>/dev/null
  fi
}

installed_version() {
  local info
  info="$(product_info_file)"
  if [ -f "$info" ]; then
    jq -r '.version // empty' "$info" 2>/dev/null
  fi
}

normalize_build() {
  local build="$1"
  printf '%s\n' "${build#*-}"
}

is_installed() {
  [ -x "$INSTALL_DIR/bin/idea.sh" ]
}

write_desktop_entry() {
  echo "🖥️ Creating desktop entry..."
  cat <<EOF | sudo tee "$DESKTOP_ENTRY" >/dev/null
[Desktop Entry]
Version=1.0
Type=Application
Name=IntelliJ IDEA Ultimate
Icon=$INSTALL_DIR/bin/idea.svg
Exec="$INSTALL_DIR/bin/idea.sh" %f
Comment=IntelliJ IDEA Ultimate Edition
Categories=Development;IDE;
Terminal=false
StartupWMClass=jetbrains-idea
EOF
}

install_release() {
  local release_json="$1"
  local idea_url latest_version latest_build tmp_dir idea_tar extracted_dir

  idea_url="$(printf '%s' "$release_json" | latest_field '.downloads.linux.link')"
  latest_version="$(printf '%s' "$release_json" | latest_field '.version')"
  latest_build="$(printf '%s' "$release_json" | latest_field '.build')"

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT
  idea_tar="$tmp_dir/ideaIU.tar.gz"

  echo "📥 Downloading IntelliJ IDEA Ultimate ${latest_version} (${latest_build})..."
  wget -O "$idea_tar" "$idea_url"

  extracted_dir="$(tar -tzf "$idea_tar" | sed -n '1s#/.*##p')"
  if [ -z "$extracted_dir" ]; then
    echo "Unable to determine IntelliJ archive root directory." >&2
    exit 1
  fi

  echo "📂 Extracting IntelliJ IDEA Ultimate..."
  sudo rm -rf "$INSTALL_DIR"
  sudo tar -xzf "$idea_tar" -C /opt/
  sudo mv "/opt/$extracted_dir" "$INSTALL_DIR"

  echo "🔗 Creating symbolic link..."
  sudo ln -sf "$INSTALL_DIR/bin/idea.sh" "$BIN_DIR/idea"
  write_desktop_entry
  rm -rf "$tmp_dir"
  trap - EXIT

  echo "🚀 IntelliJ IDEA Ultimate ${latest_version} installed successfully!"
}

show_status() {
  require_status_dependencies

  local release_json latest_version latest_build current_version current_build
  release_json="$(latest_release_json)"
  latest_version="$(printf '%s' "$release_json" | latest_field '.version')"
  latest_build="$(printf '%s' "$release_json" | latest_field '.build')"

  if ! is_installed; then
    printf 'IntelliJ IDEA Ultimate is not installed at %s\n' "$INSTALL_DIR"
    printf 'Latest available: %s (%s)\n' "$latest_version" "$latest_build"
    return 11
  fi

  current_version="$(installed_version)"
  current_build="$(installed_build)"
  printf 'Installed: %s (%s)\n' "${current_version:-unknown}" "${current_build:-unknown}"
  printf 'Latest:    %s (%s)\n' "$latest_version" "$latest_build"

  if [ -n "$current_build" ] && [ "$(normalize_build "$current_build")" = "$(normalize_build "$latest_build")" ]; then
    printf 'Status:    current\n'
    return 0
  fi

  printf 'Status:    upgrade available\n'
  return 10
}

confirm_upgrade() {
  local answer

  if [ "$AUTO_YES" = true ]; then
    return 0
  fi

  read -r -p "Upgrade IntelliJ IDEA Ultimate now? (y/N): " answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

do_install() {
  ensure_dependencies
  install_release "$(latest_release_json)"
}

do_upgrade() {
  ensure_dependencies

  local release_json latest_build current_build
  release_json="$(latest_release_json)"
  latest_build="$(printf '%s' "$release_json" | latest_field '.build')"
  current_build="$(installed_build || true)"

  if ! is_installed; then
    echo "IntelliJ IDEA Ultimate is not installed; running install."
    install_release "$release_json"
    return
  fi

  if [ -n "$current_build" ] && [ "$(normalize_build "$current_build")" = "$(normalize_build "$latest_build")" ]; then
    echo "IntelliJ IDEA Ultimate is already current (${current_build})."
    return
  fi

  show_status || true
  if confirm_upgrade; then
    install_release "$release_json"
  else
    echo "Skipped IntelliJ IDEA Ultimate upgrade."
  fi
}

parse_args "$@"

case "$ACTION" in
  install)  do_install ;;
  upgrade)  do_upgrade ;;
  status)   show_status ;;
  *)        usage_error "unknown action: $ACTION" ;;
esac
