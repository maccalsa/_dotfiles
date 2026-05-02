#!/bin/bash

set -euo pipefail

# wxGTK dev package name differs by Ubuntu/Pop release (noble+ uses 3.2).
# Use apt-cache policy: "apt-cache show" can behave oddly across apt versions.
pkg_is_installable() {
  local pkg="$1"
  local cand
  cand="$(apt-cache policy "$pkg" 2>/dev/null | awk '/^  Candidate:/ {print $2}')"
  [[ -n "$cand" && "$cand" != "(none)" ]]
}

wx_gtk_dev_package() {
  local p candidates=(
    libwxgtk3.2-gtk3-dev
    libwxgtk3.2-dev
    libwxgtk3.0-gtk3-dev
  )
  for p in "${candidates[@]}"; do
    if pkg_is_installable "$p"; then
      echo "$p"
      return 0
    fi
  done
  return 1
}

echo "🔧 Installing dependencies for asdf..."

sudo apt update

WX_DEV="$(wx_gtk_dev_package || true)"
if [[ -z "${WX_DEV:-}" ]]; then
  echo "WARN: No installable wxGTK dev package found. Erlang/OTP builds may skip or fail wx widgets." >&2
  echo "      On Pop!_/Ubuntu noble, install libwxgtk3.2-gtk3-dev (often needs universe):" >&2
  echo "        sudo add-apt-repository universe && sudo apt update" >&2
  echo "      If you pulled this repo earlier, rerun the latest installers/install_asdf.sh (not an old copy)." >&2
else
  echo "Using wxGTK dev package: $WX_DEV"
fi

# libncurses-dev replaces libncurses5-dev on newer suites; apt satisfies either.
PKGS=(
  git curl build-essential autoconf m4
  libncurses-dev
  libssl-dev libsqlite3-dev libreadline-dev zlib1g-dev
)
[[ -n "${WX_DEV:-}" ]] && PKGS+=("$WX_DEV")

sudo apt install -y "${PKGS[@]}"

ASDF_VERSION="${ASDF_VERSION:-0.18.1}"
ASDF_INSTALL_DIR="${ASDF_INSTALL_DIR:-$HOME/.local/bin}"

echo "⬇️ Installing asdf ${ASDF_VERSION}..."

case "$(uname -m)" in
  x86_64) ASDF_ARCH="amd64" ;;
  aarch64 | arm64) ASDF_ARCH="arm64" ;;
  i386 | i686) ASDF_ARCH="386" ;;
  *)
    echo "Unsupported architecture for asdf binary install: $(uname -m)" >&2
    exit 1
    ;;
esac

mkdir -p "$ASDF_INSTALL_DIR"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

curl -fsSL \
  "https://github.com/asdf-vm/asdf/releases/download/v${ASDF_VERSION}/asdf-v${ASDF_VERSION}-linux-${ASDF_ARCH}.tar.gz" \
  -o "$tmp_dir/asdf.tar.gz"
tar -xzf "$tmp_dir/asdf.tar.gz" -C "$tmp_dir"
install -m 0755 "$tmp_dir/asdf" "$ASDF_INSTALL_DIR/asdf"

echo "🔗 Configuring shell..."

shell_config="${HOME}/.zshrc"

if ! grep -q 'asdf setup' "$shell_config" 2>/dev/null; then
    {
        echo ''
        echo '# asdf setup'
        echo 'export PATH="$HOME/.local/bin:$HOME/.asdf/shims:$PATH"'
    } >> "$shell_config"
fi

export PATH="$HOME/.local/bin:$HOME/.asdf/shims:$PATH"

echo "✅ asdf installed successfully:"
asdf --version
echo "Reload your shell or run: source $shell_config"

