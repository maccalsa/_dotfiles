#!/bin/bash

set -e

# install_docker.sh
#
# This script installs and configures Docker and Docker Compose.

# Check if the user is root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Update package index
echo "Updating package index..."
sudo apt update

# Install prerequisites
echo "Installing prerequisites..."
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker's official GPG key
echo "Adding Docker's official GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add Docker's official repository
echo "Adding Docker's official repository..."
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Update package index again
echo "Updating package index again..."
sudo apt update

# Install Docker
echo "Installing Docker..."
sudo apt install -y docker-ce

# Verify Docker installation
echo "Verifying Docker installation..."
docker --version

# Enable Docker service
echo "Enabling Docker service..."
sudo systemctl enable docker

# Start Docker service
echo "Starting Docker service..."
sudo systemctl start docker

# Install Docker Compose
echo "Installing Docker Compose..."
DOCKER_COMPOSE_VERSION="1.29.2"
curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Apply executable permissions to the Docker Compose binary
echo "Applying executable permissions to Docker Compose..."
chmod +x /usr/local/bin/docker-compose

# Verify Docker Compose installation
echo "Verifying Docker Compose installation..."
docker-compose --version

echo "Docker and Docker Compose have been installed and configured successfully."

# Add the current user to the 'docker' group to allow running Docker commands without sudo
echo "Adding the current user to the 'docker' group..."
usermod -aG docker "$USER"

# Inform the user to log out and back in for the group change to take effect
echo "Please log out and log back in to apply the group changes."




