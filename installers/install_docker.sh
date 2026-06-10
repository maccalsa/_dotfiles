#!/bin/bash

# Docker Engine + Compose plugin on Ubuntu-based systems (including Pop!_OS).
# Uses Docker's signed-by repo (not deprecated apt-key).
# Full purge before reinstall: bash installers/install_docker.sh reinstall
# Nuclear wipe (removes all images/volumes): bash installers/uninstall_reset_docker.sh -y

set -euo pipefail

ACTION="install"
AUTO_YES=false

usage() {
  cat <<'USAGE'
Usage: install_docker.sh [install|reinstall|upgrade] [options]

Actions:
  install    Fresh install of Docker Engine + Compose plugin (default)
  reinstall  Purge Docker packages and config, then install fresh
  upgrade    Upgrade Docker packages in-place (no data wipe)

Options:
  -y, --yes  Non-interactive: skip confirmation prompts
  -h, --help Show this help

Notes:
  reinstall removes packages, apt repo, and ~/.docker config, but does NOT
  wipe /var/lib/docker (images/volumes). Use uninstall_reset_docker.sh -y
  for a full nuclear wipe before reinstall.
USAGE
}

step() {
  printf '\n[%s] %s\n' "$1" "$2"
}

usage_error() {
  printf 'install_docker.sh: %s\n\n' "$1" >&2
  usage >&2
  exit 2
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      install | reinstall | upgrade)
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

confirm_or_skip() {
  local msg="$1"
  if [[ "$AUTO_YES" == true ]]; then
    echo "Auto-yes: ${msg}"
    return 0
  fi
  read -r -p "${msg} Type YES to proceed: " answer
  [[ "$answer" == "YES" ]]
}

# Docker's bridge driver uses iptables. On Ubuntu/Pop!_OS, iptables v1.8 defaults
# to the nf_tables backend; a broken netlink/nft cache causes:
#   "Could not fetch rule set generation id: Invalid argument"
# and docker.service fails while creating the DOCKER NAT chain.
# Prefer iptables-legacy before the first docker start (safe on stock Debian/Ubuntu).
load_docker_kernel_modules() {
  local module
  local modules=(
    br_netfilter
    bridge
    overlay
    ip_tables
    iptable_filter
    iptable_nat
    iptable_mangle
    iptable_raw
    nf_conntrack
    nf_nat
  )

  echo "Loading kernel modules Docker commonly needs (best effort)..."
  for module in "${modules[@]}"; do
    sudo modprobe "$module" 2>/dev/null || true
  done
}

prefer_iptables_legacy() {
  local legacy nft legacy6 nft6

  legacy="/usr/sbin/iptables-legacy"
  nft="/usr/sbin/iptables-nft"
  legacy6="/usr/sbin/ip6tables-legacy"
  nft6="/usr/sbin/ip6tables-nft"

  if [[ ! -x "$legacy" ]]; then
    echo "Note: $legacy not found; skipping iptables legacy selection."
    return 0
  fi

  echo "Selecting iptables-legacy for /usr/sbin/iptables (reduces nf_tables issues with Docker)..."
  sudo update-alternatives --install /usr/sbin/iptables iptables "$legacy" 100 2>/dev/null || true
  if [[ -x "$nft" ]]; then
    sudo update-alternatives --install /usr/sbin/iptables iptables "$nft" 50 2>/dev/null || true
  fi
  sudo update-alternatives --set iptables "$legacy"

  if [[ -x "$legacy6" ]]; then
    echo "Selecting ip6tables-legacy for /usr/sbin/ip6tables..."
    sudo update-alternatives --install /usr/sbin/ip6tables ip6tables "$legacy6" 100 2>/dev/null || true
    if [[ -x "$nft6" ]]; then
      sudo update-alternatives --install /usr/sbin/ip6tables ip6tables "$nft6" 50 2>/dev/null || true
    fi
    sudo update-alternatives --set ip6tables "$legacy6"
  fi

  if ! sudo iptables -t nat -L -n >/dev/null 2>&1; then
    echo "WARN: iptables -t nat still errors after selecting legacy." >&2
    echo "      If it says \"Table does not exist\", your kernel did not expose iptable_nat." >&2
    echo "      Try rebooting after the kernel/modules package update, then rerun this script." >&2
  fi
}

purge_docker() {
  step "purge" "Stopping Docker-related units..."
  sudo systemctl stop docker.socket 2>/dev/null || true
  sudo systemctl stop docker.service 2>/dev/null || true
  sudo systemctl disable docker.service 2>/dev/null || true
  sudo systemctl disable docker.socket 2>/dev/null || true
  sudo systemctl stop containerd.service 2>/dev/null || true

  step "purge" "Removing Docker packages..."
  sudo apt-get purge -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin \
    docker-ce-rootless-extras \
    docker-model-plugin \
    2>/dev/null || true

  sudo apt-get purge -y docker.io podman-docker 2>/dev/null || true

  step "purge" "Removing Docker apt source and keyring..."
  sudo rm -f /etc/apt/sources.list.d/docker.list
  sudo rm -f /etc/apt/keyrings/docker.gpg

  step "purge" "Removing user ~/.docker config cache..."
  rm -rf "${HOME:?}/.docker"

  step "purge" "Removing old standalone Compose v1 if present..."
  sudo rm -f /usr/local/bin/docker-compose

  sudo apt-get autoremove -y
}

setup_repo() {
  step "repo" "Updating package index..."
  sudo apt-get update

  step "repo" "Installing prerequisites..."
  sudo apt-get install -y ca-certificates curl gnupg iptables

  step "repo" "Adding Docker apt keyring..."
  sudo install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
  fi

  # Pop!_OS: UBUNTU_CODENAME matches the Ubuntu base Docker packages use.
  # Pure Ubuntu: VERSION_CODENAME is enough.
  # shellcheck disable=SC1091
  . /etc/os-release
  DOCKER_CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
  if [[ -z "$DOCKER_CODENAME" ]]; then
    echo "Error: could not detect Ubuntu codename (UBUNTU_CODENAME / VERSION_CODENAME)." >&2
    exit 1
  fi

  echo "Using Docker apt suite: ${DOCKER_CODENAME} (arch $(dpkg --print-architecture))"

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${DOCKER_CODENAME} stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  step "repo" "Updating package index (Docker repo)..."
  sudo apt-get update
}

install_packages() {
  step "install" "Installing Docker Engine, CLI, containerd, Buildx, Compose plugin..."
  sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
}

start_and_verify() {
  step "verify" "Verifying binaries..."
  docker --version
  docker compose version

  load_docker_kernel_modules
  prefer_iptables_legacy

  step "service" "Enabling and starting docker.service..."
  sudo systemctl enable docker.service
  if ! sudo systemctl restart docker.service; then
    echo >&2
    echo "docker.service failed to start. Last log lines:" >&2
    sudo journalctl -u docker.service -b -n 60 --no-pager >&2 || true
    echo >&2
    echo "Common Pop!_OS / Ubuntu checks:" >&2
    echo "  - sudo journalctl -u docker.service -b -e" >&2
    echo "  - sudo dockerd --validate" >&2
    echo "  - sudo iptables -V   (expect legacy, not nf_tables)" >&2
    echo "  - sudo iptables -t nat -L -n" >&2
    echo "  - Conflicts: dpkg -l | grep -E 'docker|containerd|podman'" >&2
    echo "  - Stale data: only after backup, try sudo rm -rf /var/lib/docker (nuclear)" >&2
    exit 1
  fi

  step "group" "Adding user to docker group..."
  sudo usermod -aG docker "$USER"

  step "smoke" "Smoke test (hello-world, needs network)..."
  echo "Using sg docker so the new group applies in this session (avoids needing sudo for this check)."
  if command -v sg >/dev/null 2>&1 && sg docker -c "docker run --rm hello-world"; then
    :
  elif ! sudo docker run --rm hello-world; then
    echo "WARN: hello-world pull/run failed; docker may still be OK. Try: sudo docker ps" >&2
  fi

  echo
  echo "Done. Compose v2: docker compose up"
  echo "Your login shell still has the old group list until you log out and back in (or run: newgrp docker)."
  echo "Until then, use: sg docker -c 'docker ...'   or   sudo docker ..."
}

do_upgrade() {
  step "upgrade" "Upgrading Docker packages in-place (no data wipe)..."
  sudo apt-get update
  sudo apt-get install -y --only-upgrade \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

  step "verify" "Post-upgrade versions:"
  docker --version
  docker compose version

  step "service" "Restarting docker.service..."
  if ! sudo systemctl restart docker.service; then
    echo "WARN: docker.service failed to restart after upgrade." >&2
    sudo journalctl -u docker.service -b -n 30 --no-pager >&2 || true
  fi

  echo
  echo "Upgrade complete."
}

parse_args "$@"

case "$ACTION" in
  install)
    setup_repo
    install_packages
    start_and_verify
    ;;
  reinstall)
    if ! confirm_or_skip "This removes Docker packages, apt repo, and ~/.docker config (images/volumes in /var/lib/docker are kept)."; then
      echo "Aborted."
      exit 1
    fi
    purge_docker
    setup_repo
    install_packages
    start_and_verify
    ;;
  upgrade)
    do_upgrade
    ;;
  *)
    usage_error "unknown action: $ACTION"
    ;;
esac
