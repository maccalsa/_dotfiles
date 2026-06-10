#!/usr/bin/env bash

# set -euo pipefail is intentionally not set at the top level because SDKMAN's
# init script uses unbound variables that fail under nounset (-u).

ACTION="install"
JAVA_MAJOR_VERSION="${JAVA_MAJOR_VERSION:-25}"
JAVA_VERSION="${JAVA_VERSION:-}"

usage() {
  cat <<'USAGE'
Usage: sdkman.sh [install|upgrade] [options]

Actions:
  install  Install SDKMAN, Java (GraalCE/Temurin), and Kotlin (default)
  upgrade  Upgrade Java to the latest available build for the configured major version

Options:
  --java-major VERSION  Java major version to target (default: 25)
  --java-version VER    Exact SDKMAN Java candidate identifier (skips auto-resolve)
  -h, --help            Show this help

Environment:
  JAVA_MAJOR_VERSION  Java major version (default: 25)
  JAVA_VERSION        Exact SDKMAN candidate; overrides auto-resolve
USAGE
}

usage_error() {
  printf 'sdkman.sh: %s\n\n' "$1" >&2
  usage >&2
  exit 2
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      install | upgrade)
        ACTION="$1"
        ;;
      --java-major)
        shift
        if [ "$#" -eq 0 ] || [ -z "$1" ]; then
          usage_error "--java-major requires a value"
        fi
        JAVA_MAJOR_VERSION="$1"
        ;;
      --java-version)
        shift
        if [ "$#" -eq 0 ] || [ -z "$1" ]; then
          usage_error "--java-version requires a value"
        fi
        JAVA_VERSION="$1"
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        usage_error "unknown argument: $1"
        ;;
    esac
    shift
  done
}

load_sdkman() {
  set +u
  # shellcheck disable=SC1091
  . "$HOME/.sdkman/bin/sdkman-init.sh"
}

resolve_java_version() {
  if [ -n "$JAVA_VERSION" ]; then
    return
  fi

  JAVA_VERSION="$(sdk list java | awk -v major="$JAVA_MAJOR_VERSION" '
    $0 ~ "\\|" && $0 ~ major "\\." && $0 ~ "-graalce" { print $NF; found=1; exit }
    $0 ~ "\\|" && $0 ~ major "\\." && $0 ~ "-tem" && ! fallback { fallback=$NF }
    END { if (!found && fallback) print fallback }
  ')"

  if [ -z "$JAVA_VERSION" ]; then
    echo "Could not resolve a Java ${JAVA_MAJOR_VERSION} SDKMAN candidate." >&2
    exit 1
  fi

  echo "Resolved Java candidate: ${JAVA_VERSION}"
}

do_install() {
  if [ ! -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    echo "Installing SDKMAN..."
    curl -fsSL "https://get.sdkman.io" | bash
  else
    echo "SDKMAN already installed."
  fi

  load_sdkman
  resolve_java_version

  sdk install java "$JAVA_VERSION"
  sdk default java "$JAVA_VERSION"

  sdk install kotlin

  set -u
  echo "Java ${JAVA_VERSION} and Kotlin installed."
  java -version
}

do_upgrade() {
  if [ ! -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    echo "SDKMAN not found — run install first." >&2
    exit 1
  fi

  load_sdkman

  echo "Upgrading SDKMAN itself..."
  sdk selfupdate || true

  resolve_java_version

  echo "Installing Java ${JAVA_VERSION} and setting as default..."
  sdk install java "$JAVA_VERSION" || true
  sdk default java "$JAVA_VERSION"

  echo "Upgrading Kotlin..."
  sdk upgrade kotlin || true

  set -u
  echo "Upgrade complete."
  java -version
}

parse_args "$@"

case "$ACTION" in
  install)  do_install ;;
  upgrade)  do_upgrade ;;
  *)        usage_error "unknown action: $ACTION" ;;
esac
