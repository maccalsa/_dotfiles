#!/usr/bin/env bash
set -euo pipefail

# Colors
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
BOLD="\033[1m"
RESET="\033[0m"

# ASCII Art
echo -e "${BLUE}"
cat << "EOF"
  ____ _  _ ____ ____    ____ _  _ ____ _  _ ____ 
  | __ |  | |__| |__/    | __ |__| |  | |  | [__  
  |__] |__| |  | |  \    |__] |  | |__| |__| ___] 
     Cleanup Tool - Safe, Professional, Efficient  
EOF
echo -e "${RESET}"

echo -e "${YELLOW}${BOLD}This script will clean up your system.${RESET}"
echo -e "${BOLD}Press [Y] to confirm each cleanup task.${RESET}\n"

confirm() {
  while true; do
    read -rp "Do you want to clean up $1? [Y/n]: " yn
    case $yn in
      [Yy]*) return 0 ;;
      [Nn]*) return 1 ;;
      *) echo "Please answer Y or N." ;;
    esac
  done
}

log() {
  echo -e "${GREEN}[✔]${RESET} $1"
}

warn() {
  echo -e "${YELLOW}[!]${RESET} $1"
}

error() {
  echo -e "${RED}[✘]${RESET} $1"
}

### Cleanup: Nix
if confirm "Nix (remove old generations & garbage collect)"; then
  log "Deleting old Nix generations..."
  nix-env --delete-generations old
  log "Running Nix garbage collection..."
  nix-collect-garbage -d
  log "Nix cleanup complete."
else
  warn "Skipping Nix cleanup."
fi

### Cleanup: Docker
if confirm "Docker (remove stopped containers, dangling images, old volumes)"; then
  log "Cleaning up Docker..."
  docker system prune -af
  log "Docker cleanup complete."
else
  warn "Skipping Docker cleanup."
fi

### Cleanup: /tmp

### Non-fatal Cleanup: /tmp
if confirm "/tmp (delete all temporary files)"; then
  log "Cleaning /tmp..."
  if sudo rm -rf /tmp/* 2>/dev/null; then
    log "/tmp cleanup complete."
  else
    warn "Some files in /tmp could not be deleted. Check permissions or running processes."
fi
else
  warn "Skipping /tmp cleanup."
fi

### Cleanup: .m2 (Maven)
if confirm "Maven (.m2 cache, keeping latest versions)"; then
  log "Cleaning old Maven artifacts..."
  find ~/.m2/repository -type d -mtime +30 -exec rm -rf {} +
  log "Maven cleanup complete."
else
  warn "Skipping Maven cleanup."
fi

### Cleanup: Gradle
if confirm "Gradle (keeping latest versions)"; then
  log "Cleaning old Gradle caches..."
  rm -rf ~/.gradle/caches/modules-2/*
  log "Gradle cleanup complete."
else
  warn "Skipping Gradle cleanup."
fi

### Cleanup: Go modules
GO_LIB_PATH=$(go env GOPATH)/pkg/mod
if confirm "Go (remove old modules from $GO_LIB_PATH)"; then
  log "Cleaning Go module cache..."
  go clean -modcache
  log "Go cleanup complete."
else
  warn "Skipping Go cleanup."
fi

### Cleanup: Python packages
PYTHON_LIB_PATH=$(python3 -m site --user-site)
if confirm "Python (remove unused packages from $PYTHON_LIB_PATH)"; then
  log "Cleaning Python packages..."
  pip cache purge
  log "Python cleanup complete."
else
  warn "Skipping Python cleanup."
fi

### Cleanup: apt
if confirm "apt (remove unused packages)"; then
  log "Cleaning apt..."
  sudo apt-get clean
  sudo apt-get autoclean
  sudo apt-get autoremove -y
  log "apt cleanup complete."
else
  warn "Skipping apt cleanup."
fi

### Cleanup: old kernels
if confirm "old kernels (remove old kernels)"; then
  log "Cleaning old kernels..."
  sudo apt-get remove --purge $(dpkg -l 'linux-*' | grep '^rc' | awk '{print $2}')
  log "Old kernels cleanup complete."
else
  warn "Skipping old kernels cleanup."
fi

### Cleanup: Snap
if confirm "Snap (remove unused snaps)"; then
  log "Cleaning Snap..."
  sudo snap list --all | awk '/disabled/{print $1, $3}' |
    while read snapname revision; do
      sudo snap remove "$snapname" --revision="$revision"
    done
  log "Snap cleanup complete."
else
  warn "Skipping Snap cleanup."
fi

### Cleanup: old kernels
if confirm "old kernels (remove old kernels)"; then
  log "Cleaning old kernels..."
  sudo apt-get remove --purge $(dpkg -l 'linux-*' | grep '^rc' | awk '{print $2}')
  log "Old kernels cleanup complete."
else
  warn "Skipping old kernels cleanup."
fi

### Cleanup: Journalctl
if confirm "journalctl (remove old journalctl logs)"; then
  log "Cleaning journalctl..."
  sudo journalctl --vacuum-time=1s
  log "Journalctl cleanup complete."
else
  warn "Skipping journalctl cleanup."
fi

### Cleanup: Find and Interactively Delete Node Modules
if confirm "Find Node Modules folders for interactive cleanup"; then
  echo -e "${GREEN}[✔]${RESET} Finding Node Modules folders in non-hidden home directories..."
  
  # Find all node_modules directories in non-hidden directories, starting from home directory
  mapfile -t NODE_MODULES < <(find "$HOME" -type d -not -path '*/\.*/*' -name "node_modules" -prune 2>/dev/null)
  total_folders=${#NODE_MODULES[@]}
  
  if [ $total_folders -eq 0 ]; then
    echo -e "${YELLOW}[!]${RESET} No node_modules folders found in home directory."
  else
    echo -e "${GREEN}[✔]${RESET} Found $total_folders node_modules folders."
    
    current=0
    while [ $current -lt $total_folders ]; do
      folder="${NODE_MODULES[$current]}"
      
      # Display interface
      echo -e "\n${GREEN}Node Modules Cleanup${RESET}"
      echo -e "${BOLD}Found: $total_folders folders | Current: $((current + 1))${RESET}\n"
      echo -e "Navigate through folders:"
      echo -e "${BOLD}Press 'd' to delete the current folder"
      echo -e "Press 's' to skip to next folder"
      echo -e "Press 'x' to exit cleanup${RESET}\n"
      
      echo -e "${BLUE}----------------------------------------${RESET}"
      echo -e "${YELLOW}[$((current + 1))/$total_folders] $folder${RESET}"
      read -n 1 -r -p "Action (d/s/x)? " action
      echo
      
      case $action in
        d|D)
          if [ -d "$folder" ]; then
            echo -e "\nDeleting: $folder"
            if rm -rf "$folder" 2>/dev/null; then
              echo -e "${GREEN}[✔]${RESET} Successfully deleted: $folder"
              ((current++))
              sleep 1
              clear
            else
              echo -e "${RED}[✘]${RESET} Failed to delete: $folder"
              read -n 1 -r -p "Press any key to try next folder..."
              ((current++))
              clear
            fi
          else
            echo -e "${YELLOW}[!]${RESET} Folder no longer exists, moving to next..."
            ((current++))
            sleep 1
            clear
          fi
          ;;
        s|S)
          echo -e "${YELLOW}[!]${RESET} Skipping: $folder"
          ((current++))
          sleep 0.5
          clear
          ;;
        x|X)
          echo -e "${YELLOW}[!]${RESET} Exiting node_modules cleanup."
          break
          ;;
        *)
          echo -e "${YELLOW}Please press 'd' to delete, 's' to skip, or 'x' to exit${RESET}"
          sleep 1
          clear
          ;;
      esac
    done
  fi
  echo -e "${GREEN}[✔]${RESET} Node Modules cleanup complete."
else
  echo -e "${YELLOW}[!]${RESET} Skipping Node Modules cleanup."
fi

echo -e "\n${GREEN}${BOLD}Cleanup completed! 🎉 Your system is now clean and optimized.${RESET}"

echo -e "if you are using wsl2, you can run the following command to clean up the wsl2 cache:

# Open a PowerShell prompt and run:
wsl --shutdown Ubuntu-22.04
diskpart
# open window Diskpart
select vdisk file="[PATH]\AppData\Local\Packages\CanonicalGroupLimited.Ubuntu22.04LTS_79rhkp1fndgsc\LocalState\ext4.vhdx"
attach vdisk readonly
compact vdisk
detach vdisk
exit
"