#!/bin/bash
set -e

# Define network variables
LOCAL_NET="192.168.68.0/24"
VM_NET="192.168.122.0/24"
DOCKER_NET="172.17.0.0/16"

# 1. Reset UFW rules
echo "Resetting UFW rules..."
sudo ufw --force reset

# 2. Configure UFW rules

# Allow SSH access
echo "Allowing SSH (port 22)..."
sudo ufw allow 22/tcp

# Allow HTTP and HTTPS from local network
echo "Allowing HTTP and HTTPS from local network (${LOCAL_NET})..."
sudo ufw allow from ${LOCAL_NET} to any port 80,443 proto tcp

# Allow HTTP and HTTPS from VM network
echo "Allowing HTTP and HTTPS from VM network (${VM_NET})..."
sudo ufw allow from ${VM_NET} to any port 80,443 proto tcp

# Allow incoming HTTP(S) globally if required (optional)
# sudo ufw allow 80/tcp
# sudo ufw allow 443/tcp

# Allow incoming Twingate-related traffic from Docker network
echo "Allowing Twingate traffic from Docker (${DOCKER_NET})..."
sudo ufw allow from ${DOCKER_NET} to any port 3389 proto tcp
sudo ufw allow from ${DOCKER_NET} to any port 443 proto tcp
sudo ufw allow from ${DOCKER_NET} to any port 443 proto udp

# Allow necessary outgoing traffic for Twingate
echo "Allowing necessary outbound Twingate traffic..."
sudo ufw allow out 443/tcp
sudo ufw allow out 443/udp
sudo ufw allow out 30000:31000/tcp
sudo ufw allow out 1:65535/udp
sudo ufw allow out 53/tcp
sudo ufw allow out 53/udp
# sudo ufw allow out to any proto icmp

# Set default policies
echo "Setting default UFW policies..."
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow loopback traffic explicitly
echo "Allowing loopback interface..."
sudo ufw allow in on lo
sudo ufw allow out on lo

# Enable UFW
echo "Enabling UFW..."
sudo ufw --force enable

# Final status
echo "UFW rules configured"