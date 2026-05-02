#!/usr/bin/env bash

set -euo pipefail

DEFAULT_NODE_VERSION="${DEFAULT_NODE_VERSION:-lts/*}"
NVM_VERSION="${NVM_VERSION:-0.40.4}"

read -r -p "Enter the version of node you want to install (default: $DEFAULT_NODE_VERSION): " NODE_VERSION
if [ -z "$NODE_VERSION" ]; then
  NODE_VERSION=$DEFAULT_NODE_VERSION
fi

# Install NVM (Node Version Manager)
curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash

# Load NVM
export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh"

# Install and set Node.js as default.
nvm install "$NODE_VERSION"
nvm use "$NODE_VERSION"
nvm alias default "$NODE_VERSION"
