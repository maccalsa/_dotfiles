#!/usr/bin/env bash
set -euo pipefail

ROOT_SRC="$(findmnt -n -o SOURCE /)"
ROOT_DISK="/dev/vda"
ROOT_PART="${ROOT_DISK}3"

echo "=== VM SUMMARY ==="
echo "Memory : $(free -h | awk '/Mem:/ {print $2}')"
echo "CPUs   : $(nproc)"
echo "Disk   : $(lsblk -dn -o SIZE "$ROOT_DISK")"
echo "Root   : $(df -h / | awk 'NR==2 {print $2 " total, " $4 " free"}')"
echo

echo "=== DISK LAYOUT ==="
lsblk "$ROOT_DISK"
echo

read -rp "Do you want to extend ${ROOT_PART} and grow root filesystem? Type YES: " CONFIRM

if [[ "$CONFIRM" != "YES" ]]; then
  echo "Cancelled. No changes made."
  exit 0
fi

echo
echo "Installing growpart if needed..."
sudo apt update
sudo apt install -y cloud-guest-utils

echo
echo "Growing partition ${ROOT_PART}..."
sudo growpart "$ROOT_DISK" 3 || true

echo
echo "Checking for encryption..."

if lsblk -no TYPE "$ROOT_PART" | grep -q "part" && lsblk -no NAME "$ROOT_PART" | grep -q "vda3"; then
  CRYPT_NAME="$(lsblk -nr -o NAME,TYPE "$ROOT_PART" | awk '$2=="crypt" {print $1; exit}')"
else
  CRYPT_NAME=""
fi

if [[ -n "${CRYPT_NAME}" ]]; then
  CRYPT_DEV="/dev/mapper/${CRYPT_NAME}"
  echo "Encrypted disk detected: ${CRYPT_DEV}"

  echo "Resizing LUKS container..."
  sudo cryptsetup resize "$CRYPT_NAME"

  echo "Resizing LVM physical volume..."
  sudo pvresize "$CRYPT_DEV"
else
  echo "No encryption layer detected."

  if sudo pvs "$ROOT_PART" >/dev/null 2>&1; then
    echo "LVM physical volume detected on ${ROOT_PART}"
    sudo pvresize "$ROOT_PART"
  else
    echo "No LVM physical volume detected directly on ${ROOT_PART}"
  fi
fi

echo
echo "Finding root logical volume/filesystem..."

if [[ "$ROOT_SRC" == /dev/mapper/* ]]; then
  echo "Root is on LVM/device mapper: $ROOT_SRC"
  sudo lvextend -l +100%FREE -r "$ROOT_SRC"
else
  echo "Root is on plain partition: $ROOT_SRC"

  FSTYPE="$(findmnt -n -o FSTYPE /)"

  case "$FSTYPE" in
    ext4)
      sudo resize2fs "$ROOT_SRC"
      ;;
    xfs)
      sudo xfs_growfs /
      ;;
    *)
      echo "Unsupported filesystem type: $FSTYPE"
      echo "Partition may be grown, but filesystem was not resized."
      exit 1
      ;;
  esac
fi

echo
echo "=== DONE ==="
echo "Memory : $(free -h | awk '/Mem:/ {print $2}')"
echo "CPUs   : $(nproc)"
echo "Disk   : $(lsblk -dn -o SIZE "$ROOT_DISK")"
echo "Root   : $(df -h / | awk 'NR==2 {print $2 " total, " $4 " free"}')"
echo
lsblk "$ROOT_DISK"
