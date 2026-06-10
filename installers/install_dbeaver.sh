#!/usr/bin/env bash
set -euo pipefail

# Install, upgrade, or check DBeaver Community Edition from the official apt repo.

ACTION="install"
AUTO_YES=false

DBEAVER_KEYRING="/usr/share/keyrings/dbeaver.gpg"
DBEAVER_SOURCE="/etc/apt/sources.list.d/dbeaver.list"
DBEAVER_PACKAGE="dbeaver-ce"

usage() {
  cat <<'USAGE'
Usage: install_dbeaver.sh [install|upgrade|status] [options]

Actions:
  install   Add the DBeaver apt repo and install DBeaver CE (default)
  upgrade   Upgrade DBeaver CE in-place when apt has a newer package
  status    Show installed/candidate versions; exits 10 when an upgrade is available

Options:
  -y, --yes   Do not prompt before upgrading
  -h, --help  Show this help
USAGE
}

usage_error() {
  printf 'install_dbeaver.sh: %s\n\n' "$1" >&2
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

ensure_repo() {
  echo "🐝 Ensuring DBeaver repository..."
  sudo install -d -m 0755 /usr/share/keyrings
  wget -O - https://dbeaver.io/debs/dbeaver.gpg.key | sudo gpg --dearmor -o "$DBEAVER_KEYRING"
  echo "deb [arch=amd64 signed-by=${DBEAVER_KEYRING}] https://dbeaver.io/debs/dbeaver-ce /" |
    sudo tee "$DBEAVER_SOURCE" >/dev/null
}

installed_version() {
  dpkg-query -W -f='${Version}' "$DBEAVER_PACKAGE" 2>/dev/null || true
}

candidate_version() {
  apt-cache policy "$DBEAVER_PACKAGE" 2>/dev/null | awk '/^[[:space:]]*Candidate:/ {print $2}'
}

show_status() {
  local installed candidate
  installed="$(installed_version)"
  candidate="$(candidate_version)"

  if [ -z "$installed" ]; then
    printf 'DBeaver CE is not installed.\n'
    printf 'Candidate: %s\n' "${candidate:-unknown}"
    return 11
  fi

  printf 'Installed: %s\n' "$installed"
  printf 'Candidate: %s\n' "${candidate:-unknown}"

  if [ -n "$candidate" ] && [ "$candidate" != "(none)" ] && [ "$installed" != "$candidate" ]; then
    printf 'Status:    upgrade available\n'
    return 10
  fi

  printf 'Status:    current\n'
  return 0
}

confirm_upgrade() {
  local answer

  if [ "$AUTO_YES" = true ]; then
    return 0
  fi

  read -r -p "Upgrade DBeaver CE now? (y/N): " answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

do_install() {
  ensure_repo

  echo "📥 Installing DBeaver Community Edition..."
  sudo apt update
  sudo apt install -y "$DBEAVER_PACKAGE"

  echo "🚀 DBeaver installed successfully!"
}

do_upgrade() {
  ensure_repo
  sudo apt update

  if ! dpkg-query -W "$DBEAVER_PACKAGE" >/dev/null 2>&1; then
    echo "DBeaver CE is not installed; running install."
    sudo apt install -y "$DBEAVER_PACKAGE"
    return
  fi

  if show_status; then
    return
  fi

  if confirm_upgrade; then
    sudo apt-get install -y --only-upgrade "$DBEAVER_PACKAGE"
    show_status || true
  else
    echo "Skipped DBeaver CE upgrade."
  fi
}

parse_args "$@"

case "$ACTION" in
  install)  do_install ;;
  upgrade)  do_upgrade ;;
  status)   show_status ;;
  *)        usage_error "unknown action: $ACTION" ;;
esac
