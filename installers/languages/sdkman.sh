#!/usr/bin/env bash

set -euo pipefail

JAVA_MAJOR_VERSION="${JAVA_MAJOR_VERSION:-21}"

# Install SDKMAN
if [ ! -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
  curl -fsSL "https://get.sdkman.io" | bash
fi

# Load SDKMAN (for this script session)
# shellcheck disable=SC1091
. "$HOME/.sdkman/bin/sdkman-init.sh"

# Install the latest available Java 21 GraalCE build, with Temurin as fallback.
JAVA_VERSION="${JAVA_VERSION:-$(sdk list java | awk -v major="$JAVA_MAJOR_VERSION" '
  $0 ~ "\\|" && $0 ~ major "\\." && $0 ~ "-graalce" { print $NF; found=1; exit }
  $0 ~ "\\|" && $0 ~ major "\\." && $0 ~ "-tem" && ! fallback { fallback=$NF }
  END { if (!found && fallback) print fallback }
')}"

if [ -z "$JAVA_VERSION" ]; then
  echo "Could not resolve a Java ${JAVA_MAJOR_VERSION} SDKMAN candidate." >&2
  exit 1
fi

sdk install java "$JAVA_VERSION"
sdk default java "$JAVA_VERSION"

# Install Kotlin
sdk install kotlin
