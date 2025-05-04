#! /bin/bash

set -e

# chmod-tree.sh
#
# This script takes a directory path as an argument and recursively changes the
# permissions of all files and directories within it to 755.

DEFAULT_DIR="."
DEFAULT_PERMS="755"
DEFAULT_EXT="sh"

read -p "Enter the directory path [$DEFAULT_DIR]: " DIR
read -p "Enter the permissions [$DEFAULT_PERMS]: " PERMS
read -p "Enter the file extension [$DEFAULT_EXT]: " EXT

# Set the directory path to the first argument
DIR="${DIR:-$DEFAULT_DIR}"
PERMS="${PERMS:-$DEFAULT_PERMS}"
EXT="${EXT:-$DEFAULT_EXT}"

# Check if the directory exists
if [ ! -d "$DIR" ]; then
    echo "Error: Directory '$DIR' does not exist."
    exit 1
fi

# Recursively change permissions to 755
find "$DIR" -type f -name "*.$EXT" -print0 | xargs -0 chmod $PERMS

