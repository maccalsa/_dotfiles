#!/usr/bin/env bash

# Install Cursor on Omarchy.
# System upgrades remain managed by `omarchy update`.

set -euo pipefail

readonly CURSOR_PACKAGE="cursor-bin"

usage() {
    cat <<'USAGE'
Usage: install-cursor.sh

Ensures Cursor is installed.

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

    printf '\n==> Ensuring Cursor is installed (%s)\n' "$CURSOR_PACKAGE"
    yay -S --needed --noconfirm "$CURSOR_PACKAGE"

    printf '\n==> Verifying installation\n'
    if ! command -v cursor >/dev/null 2>&1; then
        printf 'Warning: Cursor appears installed, but %q is not on PATH.\n' cursor >&2
    else
        printf '✓ Cursor is available as %q\n' cursor
    fi

    printf '\nCursor installation complete.\n'
    printf 'System upgrades remain managed by: omarchy update\n'
}

main "$@"
