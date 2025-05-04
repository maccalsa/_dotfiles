DEFAULT_NODE_VERSION="22"

read -p "Enter the version of node you want to install (default: $DEFAULT_NODE_VERSION): " NODE_VERSION
if [ -z "$NODE_VERSION" ]; then
  NODE_VERSION=$DEFAULT_NODE_VERSION
fi

# Install NVM (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Load NVM
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"

# Install and set Node.js 22 as default
nvm install $NODE_VERSION
nvm use $NODE_VERSION
nvm alias default $NODE_VERSION