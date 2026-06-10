#!/usr/bin/env bash
set -euo pipefail

echo "=================================================="
echo " Ubuntu VM disk resize helper"
echo "=================================================="
echo
echo "BEFORE running this script:"
echo
echo "1. Shut down the VM"
echo "2. Open virt-manager"
echo "3. Select the VM"
echo "4. Open 'Show virtual hardware details'"
echo "5. Select the disk"
echo "6. Increase the disk size"
echo "7. Boot the VM again"
echo
read -rp "Have you already increased the disk size in virt-manager? Type YES to continue: " confirm

if [[ "$confirm" != "YES" ]]; then
  echo "Aborted. Resize the virtual disk in virt-manager first."
  exit 1
fi

echo
echo "Current disks:"
lsblk
echo

ROOT_DEVICE="$(findmnt -n -o SOURCE /)"
echo "Root filesystem is on: $ROOT_DEVICE"

DISK="/dev/sda"
PARTITION="${DISK}3"

echo
echo "This script assumes a standard Ubuntu install using:"
echo "  Disk:      $DISK"
echo "  Partition: $PARTITION"
echo
read -rp "Continue with these values? Type YES to continue: " confirm2

if [[ "$confirm2" != "YES" ]]; then
  echo "Aborted."
  exit 1
fi

echo
echo "Installing growpart if needed..."
sudo apt update
sudo apt install -y cloud-guest-utils

echo
echo "Growing partition $PARTITION..."
sudo growpart "$DISK" 3

echo
echo "Checking if this system uses LVM..."

if sudo pvs "$PARTITION" >/dev/null 2>&1; then
  echo "LVM detected."

  echo "Resizing physical volume..."
  sudo pvresize "$PARTITION"

  LV_PATH="$(findmnt -n -o SOURCE /)"
  echo "Root logical volume: $LV_PATH"

  echo "Extending logical volume to use all free space..."
  sudo lvextend -l +100%FREE "$LV_PATH"

  FSTYPE="$(findmnt -n -o FSTYPE /)"

  if [[ "$FSTYPE" == "ext4" ]]; then
    echo "Resizing ext4 filesystem..."
    sudo resize2fs "$LV_PATH"
  elif [[ "$FSTYPE" == "xfs" ]]; then
    echo "Resizing xfs filesystem..."
    sudo xfs_growfs /
  else
    echo "Unsupported filesystem type: $FSTYPE"
    exit 1
  fi

else
  echo "No LVM detected."

  FSTYPE="$(findmnt -n -o FSTYPE /)"

  if [[ "$FSTYPE" == "ext4" ]]; then
    echo "Resizing ext4 filesystem on $ROOT_DEVICE..."
    sudo resize2fs "$ROOT_DEVICE"
  elif [[ "$FSTYPE" == "xfs" ]]; then
    echo "Resizing xfs filesystem..."
    sudo xfs_growfs /
  else
    echo "Unsupported filesystem type: $FSTYPE"
    exit 1
  fi
fi

echo
echo "Resize complete."
echo
df -h /
echo
lsblk
