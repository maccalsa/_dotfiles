#!/usr/bin/env bash
# apply-stow.sh - Install GNU Stow if needed and apply the Omarchy overlay packages.
#
# Packages live in arch/stow/ and layer on top of Omarchy. They do not replace
# LazyVim, ~/.config/tmux/tmux.conf, or ~/.config/git/config.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
STOW_DIR="$DOTFILES_ROOT/arch/stow"
PACKAGES=(git nvim tmux)
LAZYVIM_JSON="${HOME}/.config/nvim/lazyvim.json"
LAZYVIM_EXTRAS=(
  lazyvim.plugins.extras.lang.go
  lazyvim.plugins.extras.lang.rust
  lazyvim.plugins.extras.lang.typescript
  lazyvim.plugins.extras.lang.json
  lazyvim.plugins.extras.lang.yaml
  lazyvim.plugins.extras.lang.docker
  lazyvim.plugins.extras.lang.java
  lazyvim.plugins.extras.lang.markdown
  lazyvim.plugins.extras.lang.kotlin
)
TMUX_CONF="${HOME}/.config/tmux/tmux.conf"
TMUX_SOURCE_LINE='source-file -q ~/.config/tmux/tmux.conf.local'
UBUNTU_GIT_MARKER='/stow/git/'
ARCH_GIT_MARKER='/arch/stow/git/'

MODE="restow"
DRY_RUN=false

usage() {
  cat <<'USAGE'
Usage: apply-stow.sh [OPTIONS]

Install GNU Stow if missing, then restow the Omarchy overlay packages from
arch/stow onto $HOME (git, nvim, tmux).

Options:
  --dry-run   Show what would happen; do not change the system
  --delete    Unstow the overlay packages and drop the tmux source-file line
  -h, --help  Show this help

Examples:
  ./arch/omarchy/apply-stow.sh
  ./arch/omarchy/apply-stow.sh --dry-run
  ./arch/omarchy/apply-stow.sh --delete
USAGE
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

log() {
  printf '%s\n' "$*"
}

run() {
  if [[ "$DRY_RUN" == true ]]; then
    printf '[dry-run] %s\n' "$*"
    return 0
  fi
  "$@"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        DRY_RUN=true
        ;;
      --delete)
        MODE="delete"
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        die "Unknown option: $1"
        ;;
    esac
    shift
  done
}

require_layout() {
  [[ -d "$STOW_DIR" ]] || die "Missing overlay stow directory: $STOW_DIR"

  local package
  for package in "${PACKAGES[@]}"; do
    [[ -d "$STOW_DIR/$package" ]] || die "Missing overlay package: $STOW_DIR/$package"
  done
}

ensure_stow() {
  if command -v stow >/dev/null 2>&1; then
    log "stow is already installed"
    return 0
  fi

  if [[ "$DRY_RUN" == true ]]; then
    log "[dry-run] Would install GNU stow"
    return 0
  fi

  log "Installing GNU stow"

  if command -v omarchy >/dev/null 2>&1; then
    omarchy pkg add stow
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm stow
  else
    die "GNU stow is required. Install stow and retry."
  fi

  command -v stow >/dev/null 2>&1 || die "stow install completed but stow is not on PATH"
}

path_owner() {
  stat -c '%U' "$1" 2>/dev/null || true
}

fix_root_owned_tree() {
  local path="$1"

  [[ -e "$path" ]] || return 0

  local owner
  owner="$(path_owner "$path")"
  if [[ "$owner" != "root" ]]; then
    return 0
  fi

  log "Taking ownership of $path (currently root-owned user config)"
  run sudo chown -R "${USER}:${USER}" "$path"
}

fix_overlay_targets() {
  fix_root_owned_tree "${HOME}/.config/nvim"
  fix_root_owned_tree "${HOME}/.config/tmux"
  fix_root_owned_tree "${HOME}/.config/git"
  fix_root_owned_tree "${HOME}/.config/omarchy/hooks"
}

ubuntu_gitconfig_symlink() {
  local gitconfig="${HOME}/.gitconfig"
  local link_target

  [[ -L "$gitconfig" ]] || return 1

  link_target="$(readlink "$gitconfig")"
  if [[ "$link_target" == *"$ARCH_GIT_MARKER"* ]]; then
    return 1
  fi
  [[ "$link_target" == *"$UBUNTU_GIT_MARKER"* ]]
}

remove_ubuntu_git_symlink() {
  local gitconfig="${HOME}/.gitconfig"

  ubuntu_gitconfig_symlink || return 0

  log "Removing Ubuntu git overlay symlink: $gitconfig -> $(readlink "$gitconfig")"
  run rm "$gitconfig"
}

tmux_source_present() {
  [[ -f "$TMUX_CONF" ]] && grep -qxF "$TMUX_SOURCE_LINE" "$TMUX_CONF"
}

ensure_tmux_source() {
  if tmux_source_present; then
    log "tmux.conf already sources tmux.conf.local"
    return 0
  fi

  if [[ ! -f "$TMUX_CONF" ]]; then
    log "No $TMUX_CONF yet; skip source-file line"
    return 0
  fi

  log "Appending tmux overlay source-file line"
  if [[ "$DRY_RUN" == true ]]; then
    log "[dry-run] Would append: $TMUX_SOURCE_LINE"
    return 0
  fi

  printf '\n%s\n' "$TMUX_SOURCE_LINE" >>"$TMUX_CONF"
}

remove_tmux_source() {
  [[ -f "$TMUX_CONF" ]] || return 0
  tmux_source_present || return 0

  log "Removing tmux overlay source-file line"
  if [[ "$DRY_RUN" == true ]]; then
    log "[dry-run] Would remove: $TMUX_SOURCE_LINE"
    return 0
  fi

  local tmp
  tmp="$(mktemp)"
  grep -vxF "$TMUX_SOURCE_LINE" "$TMUX_CONF" >"$tmp"
  mv "$tmp" "$TMUX_CONF"
}

stow_args() {
  local extra=()
  if [[ "$DRY_RUN" == true ]]; then
    extra+=(--simulate --verbose)
  fi

  case "$MODE" in
    delete)
      extra+=(--delete)
      ;;
    restow)
      extra+=(--restow)
      ;;
  esac

  printf '%s\n' "${extra[@]}"
}

run_stow_package() {
  local package="$1"
  local extra

  mapfile -t extra < <(stow_args)
  log "stow --dir=$STOW_DIR --target=$HOME --no-folding ${extra[*]} $package"

  if stow --dir="$STOW_DIR" --target="$HOME" --no-folding "${extra[@]}" "$package"; then
    return 0
  fi

  if [[ "$DRY_RUN" == true && "$MODE" == "restow" && "$package" == git ]] && ubuntu_gitconfig_symlink; then
    log "git would stow after removing the Ubuntu ~/.gitconfig symlink"
    return 0
  fi

  die "stow failed for package $package"
}

run_stow() {
  local package
  for package in "${PACKAGES[@]}"; do
    run_stow_package "$package"
  done
}

merge_lazyvim_extras() {
  if [[ ! -f "$LAZYVIM_JSON" ]]; then
    log "No $LAZYVIM_JSON yet; skip LazyVim extras merge"
    return 0
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    die "python3 is required to merge LazyVim extras into $LAZYVIM_JSON"
  fi

  log "Merging language extras into $LAZYVIM_JSON"
  if [[ "$DRY_RUN" == true ]]; then
    log "[dry-run] Would ensure extras: ${LAZYVIM_EXTRAS[*]}"
    return 0
  fi

  python3 - "$LAZYVIM_JSON" "${LAZYVIM_EXTRAS[@]}" <<'PY'
import json
import sys

path = sys.argv[1]
wanted = sys.argv[2:]

with open(path, encoding="utf-8") as handle:
    data = json.load(handle)

extras = list(data.get("extras") or [])
changed = False
for extra in wanted:
    if extra not in extras:
        extras.append(extra)
        changed = True

if not changed:
    raise SystemExit(0)

data["extras"] = extras
with open(path, "w", encoding="utf-8") as handle:
    json.dump(data, handle, indent=2)
    handle.write("\n")
PY
}

main() {
  parse_args "$@"
  require_layout

  if [[ "$MODE" == "delete" ]]; then
    command -v stow >/dev/null 2>&1 || die "GNU stow is required to unstow packages"
    fix_overlay_targets
    run_stow
    remove_tmux_source
    log "Overlay packages removed"
    return 0
  fi

  ensure_stow
  fix_overlay_targets
  remove_ubuntu_git_symlink
  run_stow
  merge_lazyvim_extras
  ensure_tmux_source
  log "Overlay packages applied"
}

main "$@"
