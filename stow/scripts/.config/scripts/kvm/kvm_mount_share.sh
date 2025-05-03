#!/bin/bash

# Prompt the user for inputs
read -p "Please enter the source (mount folder): " source
read -p "Please enter the KVM (mount): " kvm_value

# Check if the provided directory exists, and if not, create it
if [ ! -d "/mnt/$source" ]; then
    sudo mkdir "/mnt/$source"
fi

# Mount the directory
sudo mount -t virtiofs "$kvm_value" "/mnt/$source"

# Change directory
cd "/mnt/$source"

# Print current directory to confirm
echo "Now in directory: $(pwd)"