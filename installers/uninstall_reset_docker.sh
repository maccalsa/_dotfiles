#!/bin/bash

# Nuclear uninstall + data wipe for Docker Engine (Ubuntu / Pop!_OS / Debian-derived).
# Pairs with install_docker.sh for a clean reinstall.
#
# Usage:
#   bash installers/uninstall_reset_docker.sh           # confirms once
#   bash installers/uninstall_reset_docker.sh -y        # non-interactive (yolo)
#   bash installers/uninstall_reset_docker.sh --yes

set -euo pipefail

AUTO_YES=false
for arg in "$@"; do
  case "$arg" in
    -y|--yes) AUTO_YES=true ;;
    -h|--help)
      grep '^#' "$0" | head -20 | sed 's/^# //'
      exit 0
      ;;
  esac
done

confirm_or_yolo() {
  local msg="$1"
  if [[ "$AUTO_YES" == true ]]; then
    echo "Yolo: ${msg}"
    return 0
  fi
  read -r -p "${msg} Type YES to proceed: " answer
  [[ "$answer" == "YES" ]]
}

echo "Stopping Docker-related units..."
sudo systemctl stop docker.socket 2>/dev/null || true
sudo systemctl stop docker.service 2>/dev/null || true
sudo systemctl disable docker.service 2>/dev/null || true
sudo systemctl disable docker.socket 2>/dev/null || true
sudo systemctl stop containerd.service 2>/dev/null || true

if ! confirm_or_yolo "This removes Docker packages, apt repo stub, config, ALL images/containers/volumes under /var/lib/docker and container state."; then
  echo "Aborted."
  exit 1
fi

echo "Purging Docker packages (ignore \"not installed\")..."
sudo apt-get purge -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin \
  docker-ce-rootless-extras \
  docker-model-plugin \
  2>/dev/null || true

echo "Removing leftover docker.io / podman-docker if present (optional conflict)..."
sudo apt-get purge -y docker.io podman-docker 2>/dev/null || true

echo "Deleting Docker apt source and keyring..."
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /etc/apt/keyrings/docker.gpg

echo "Removing config and runtime data..."
sudo rm -rf /etc/docker
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
sudo rm -rf /run/docker
sudo rm -rf /run/containerd

echo "Removing user ~/.docker config cache (logged-in registries etc.)..."
rm -rf "${HOME:?}/.docker"

echo "Removing old standalone Compose v1 if present..."
sudo rm -f /usr/local/bin/docker-compose

echo "apt-get autoremove..."
sudo apt-get update
sudo apt-get autoremove -y

echo "Done. You are still in the 'docker' group until you remove yourself (harmless)."
echo "  sudo deluser \"$(whoami)\" docker   # optional"
echo "Reinstall:  bash installers/install_docker.sh"
