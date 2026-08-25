#!/usr/bin/env bash

# Install Cursor and IntelliJ IDEA Ultimate on Omarchy.
# System upgrades remain managed by `omarchy update`.

set -euo pipefail

readonly CURSOR_PACKAGE="cursor-bin"
readonly INTELLIJ_PACKAGE="intellij-idea-ultimate-edition"

usage() {
    cat <<'USAGE'
Usage: install-ides.sh

Ensures these applications are installed:
  - Cursor
  - IntelliJ IDEA Ultimate

Options:
  -h, --help  Show this help

System upgrades are intentionally left to:
  omarchy update
USAGE
}

require_command() {
    local command_name="$1"
    local install_hint="$2"

    if ! command -v "$command_name" >/dev/null 2>&1; then
        printf 'Error: required command %q was not found.\n' "$command_name" >&2
        printf '%s\n' "$install_hint" >&2
        exit 1
    fi
}

install_aur_package() {
    local package_name="$1"
    local application_name="$2"

    printf '\n==> Ensuring %s is installed (%s)\n' \
        "$application_name" "$package_name"

    yay -S --needed --noconfirm "$package_name"
}

verify_installation() {
    local executable="$1"
    local application_name="$2"

    if ! command -v "$executable" >/dev/null 2>&1; then
        printf 'Warning: %s appears installed, but %q is not on PATH.\n' \
            "$application_name" "$executable" >&2
        return 1
    fi

    printf '✓ %s is available as %q\n' \
        "$application_name" "$executable"
}

main() {
    if [ "$#" -gt 0 ]; then
        case "$1" in
            -h | --help)
                usage
                return 0
                ;;
            *)
                printf 'Error: unknown argument: %s\n\n' "$1" >&2
                usage >&2
                return 2
                ;;
        esac
    fi

    require_command pacman \
        "This installer requires Arch Linux or Omarchy."

    require_command yay \
        "Omarchy normally includes yay. Install or restore it before running this script."

    install_aur_package "$CURSOR_PACKAGE" "Cursor"
    install_aur_package "$INTELLIJ_PACKAGE" "IntelliJ IDEA Ultimate"

    printf '\n==> Verifying installations\n'

    verify_installation cursor "Cursor" || true
    verify_installation idea "IntelliJ IDEA Ultimate" || true

    printf '\nIDE installation complete.\n'
    printf 'System upgrades remain managed by: omarchy update\n'
}

main "$@"
