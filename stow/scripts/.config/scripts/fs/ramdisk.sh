#!/bin/bash

# Function to create and mount a temporary memory disk
create_memory_disk() {
    read -p "Enter the size of the memory disk (e.g., 512M, 1G): " size
    read -p "Enter the mount point (e.g., /mnt/myramdisk): " mount_point
    sudo mkdir -p "$mount_point"
    sudo mount -t tmpfs -o size=$size tmpfs "$mount_point"
    echo "Memory disk created and mounted at $mount_point"
}

# Function to display all mounted memory disks
display_memory_disks() {
    echo "Currently mounted memory disks:"
    sudo mount | grep tmpfs | grep -v '/sys' | grep -v '/dev'
}

# Function to delete a memory disks
delete_memory_disk() {
    read -p "Enter the mount point of the memory disk to unmount and delete (e.g., /mnt/myramdisk): " mount_point
    sudo umount "$mount_point" && sudo rmdir "$mount_point"
    echo "Memory disk at $mount_point has been unmounted and deleted"
}

# Main menu for user actions
while true; do
    echo "Choose an option:"
    echo "1) Create a memory disk"
    echo "2) Display mounted memory disks"
    echo "3) Delete a memory disk"
    echo "4) Exit"
    read -p "Enter your choice: " choice

    case $choice in
        1)
            create_memory_disk
            ;;
        2)
            display_memory_disks
            ;;
        3)
            delete_memory_disk
            ;;
        4)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option, please try again."
            ;;
    esac
done