#!/usr/bin/env bash

# Install IntelliJ IDEA Ultimate on Omarchy.
# System upgrades remain managed by `omarchy update`.

set -euo pipefail

readonly INTELLIJ_PACKAGE="intellij-idea-ultimate-edition"

usage() {
    cat <<'USAGE'
Usage: install-intellij.sh

Ensures IntelliJ IDEA Ultimate is installed.

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

    printf '\n==> Ensuring IntelliJ IDEA Ultimate is installed (%s)\n' \
        "$INTELLIJ_PACKAGE"
    yay -S --needed --noconfirm "$INTELLIJ_PACKAGE"

    printf '\n==> Verifying installation\n'
    if ! command -v idea >/dev/null 2>&1; then
        printf 'Warning: IntelliJ IDEA Ultimate appears installed, but %q is not on PATH.\n' idea >&2
    else
        printf '✓ IntelliJ IDEA Ultimate is available as %q\n' idea
    fi

    printf '\nIntelliJ installation complete.\n'
    printf 'System upgrades remain managed by: omarchy update\n'
}

main "$@"
