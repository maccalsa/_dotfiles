#!/usr/bin/env bash

# Omarchy / Arch developer workstation bootstrap
#
# Philosophy:
#   - Install as much as possible automatically.
#   - Do NOT abort the entire bootstrap because one optional tool is unavailable.
#   - Report exactly what is missing or failed.
#   - Only stop for truly fundamental failures such as pacman being unavailable.
#
# Toolchain ownership:
#   pacman  -> base tools, pass/GPG, Git, Docker, Go, Odin where available
#   SDKMAN  -> Java 25+, Gradle, Kotlin CLI
#   NVM     -> Node LTS
#   rustup  -> Rust stable
#
# Usage:
#   chmod +x omarchy-dev-bootstrap-v2.sh
#   ./omarchy-dev-bootstrap-v2.sh

set -uo pipefail

JAVA_CANDIDATE="${JAVA_CANDIDATE:-25-tem}"
# Kotlin 2.2 cannot emit JVM 25 bytecode; 2.3+ can. Keep this in step with SDKMAN's kotlinc.
KOTLIN_PLUGIN_VERSION="${KOTLIN_PLUGIN_VERSION:-2.4.10}"
NODE_VERSION="${NODE_VERSION:-lts/*}"
SMOKE_ROOT="${SMOKE_ROOT:-$HOME/code/smoke-tests}"

declare -a OK_ITEMS=()
declare -a WARN_ITEMS=()
declare -a FAIL_ITEMS=()

blue='\033[1;34m'
green='\033[1;32m'
yellow='\033[1;33m'
red='\033[1;31m'
reset='\033[0m'

section() {
  printf '\n%b==>%b %s\n' "$blue" "$reset" "$1"
}

ok() {
  printf '%b✓%b %s\n' "$green" "$reset" "$1"
  OK_ITEMS+=("$1")
}

warn() {
  printf '%b!%b %s\n' "$yellow" "$reset" "$1"
  WARN_ITEMS+=("$1")
}

fail() {
  printf '%b✗%b %s\n' "$red" "$reset" "$1"
  FAIL_ITEMS+=("$1")
}

have() {
  command -v "$1" >/dev/null 2>&1
}

append_once() {
  local line="$1"
  local file="$2"

  mkdir -p "$(dirname "$file")"
  touch "$file"

  if ! grep -qxF "$line" "$file" 2>/dev/null; then
    printf '%s\n' "$line" >> "$file"
  fi
}

# SDKMAN is not nounset-safe: init reads unset env vars, and commands such as
# `sdk install java <version>` assign optional `$3` (`folder="$3"`).
without_nounset() {
  local rc
  set +u
  "$@"
  rc=$?
  set -u
  return "$rc"
}

source_sdkman() {
  local init="${SDKMAN_DIR}/bin/sdkman-init.sh"
  [[ -s "$init" ]] || return 1
  # shellcheck disable=SC1090
  without_nounset source "$init"
}

sdkman_nounset_safe_init_block() {
  cat <<'EOF'
if [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
    set +u
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    set -u
fi
EOF
}

# The SDKMAN installer appends a one-liner of the form:
#   [[ -s ".../sdkman-init.sh" ]] && source ".../sdkman-init.sh"
# Replace that with a nounset-safe wrapper. Skip files that already use it.
patch_sdkman_init_in_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0

  local tmp
  tmp="$(mktemp)"
  local replaced=0
  local already_safe=0

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == *sdkman-init.sh* && "$line" == *'&&'* ]]; then
      if ((replaced == 0)); then
        sdkman_nounset_safe_init_block >> "$tmp"
        replaced=1
      fi
      continue
    fi
    if [[ "$line" == *sdkman-init.sh* ]]; then
      already_safe=1
    fi
    printf '%s\n' "$line" >> "$tmp"
  done < "$file"

  if ((replaced == 0 && already_safe == 0)); then
    sdkman_nounset_safe_init_block >> "$tmp"
    replaced=1
  fi

  if ((replaced == 1)); then
    mv "$tmp" "$file"
    ok "SDKMAN init in $file is nounset-safe"
  else
    rm -f "$tmp"
  fi
}

patch_sdkman_shell_rcs() {
  local rc
  local seen=":"

  for rc in "$SHELL_RC" "$HOME/.bashrc" "$HOME/.zshrc"; do
    [[ -f "$rc" ]] || continue
    [[ "$seen" == *":$rc:"* ]] && continue
    seen+="$rc:"
    patch_sdkman_init_in_file "$rc"
  done
}

pacman_has_package() {
  pacman -Si "$1" >/dev/null 2>&1
}

install_pacman_package() {
  local package="$1"

  if pacman -Q "$package" >/dev/null 2>&1; then
    ok "$package already installed"
    return 0
  fi

  if ! pacman_has_package "$package"; then
    warn "pacman package '$package' is not available in the configured repositories"
    return 1
  fi

  if sudo pacman -S --needed --noconfirm "$package"; then
    ok "Installed $package"
    return 0
  fi

  fail "Could not install $package with pacman"
  return 1
}

run_check() {
  local label="$1"
  shift

  if "$@" >/dev/null 2>&1; then
    ok "$label"
    return 0
  fi

  warn "$label failed"
  return 1
}

SHELL_RC="$HOME/.zshrc"
if [[ "${SHELL:-}" == *bash ]]; then
  SHELL_RC="$HOME/.bashrc"
fi

# ---------------------------------------------------------------------------
# Arch packages
# ---------------------------------------------------------------------------

section "Installing base software"

PACMAN_PACKAGES=(
  base-devel
  wget
  clang
  lld
  llvm
)

for package in "${PACMAN_PACKAGES[@]}"; do
  install_pacman_package "$package" || true
done

# ---------------------------------------------------------------------------
# Docker
# ---------------------------------------------------------------------------
# Omarchy 4.0.0 put the install user in the docker group, so `docker ps` worked
# on a fresh install. 4.0.1 made that opt-in (migration 1787580187 runs
# `gpasswd -d "$USER" docker`). Restore the 4.0.0 workstation behaviour.

section "Configuring Docker"

if have docker; then
  if sudo systemctl enable --now docker.socket; then
    ok "Docker socket enabled"
  else
    warn "Docker is installed but docker.socket could not be enabled"
  fi

  if getent group docker | grep -qw "$USER"; then
    ok "$USER is already in the docker group"
  else
    if sudo usermod -aG docker "$USER"; then
      ok "Added $USER to the docker group"
      warn "Reboot before expecting passwordless Docker in this session (group membership is only picked up at login)"
    else
      fail "Could not add $USER to the docker group"
    fi
  fi
else
  fail "Docker executable is unavailable"
fi

# ---------------------------------------------------------------------------
# Go
# ---------------------------------------------------------------------------

section "Installing Go"

if have go; then
  ok "Go already installed ($(go version 2>/dev/null | head -n 1))"
elif install_pacman_package go; then
  :
else
  fail "Go is not installed"
  warn "Install manually with: sudo pacman -S --needed go"
fi

if have gopls; then
  ok "gopls already installed"
else
  install_pacman_package gopls || true
fi

if have go; then
  mkdir -p "$HOME/go/bin"
  append_once 'export PATH="$PATH:$HOME/go/bin"' "$SHELL_RC"
  export PATH="$PATH:$HOME/go/bin"
  ok "Go bin path configured in $SHELL_RC"
  run_check "go version" go version
else
  fail "Go executable is unavailable"
fi

# Odin package naming/repository availability can vary over time.
section "Installing Odin"

if have odin; then
  ok "Odin already installed"
else
  if install_pacman_package odin; then
    :
  elif have yay; then
    warn "Trying AUR fallback for Odin"
    if yay -S --needed --noconfirm odin; then
      ok "Installed Odin through yay"
    else
      fail "Could not install Odin automatically"
      warn "Fix manually with: yay -Ss odin"
    fi
  else
    fail "Odin is not installed and no usable pacman package was found"
    warn "Install yay or build Odin manually, then run: odin version"
  fi
fi

# ---------------------------------------------------------------------------
# NVM / Node
# ---------------------------------------------------------------------------

section "Installing NVM and Node"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
mkdir -p "$NVM_DIR"

if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  if have curl; then
    NVM_INSTALL_VERSION="${NVM_INSTALL_VERSION:-v0.40.3}"

    if curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_INSTALL_VERSION}/install.sh" | bash; then
      ok "Installed NVM"
    else
      fail "Could not install NVM"
    fi
  else
    fail "curl is unavailable, so NVM could not be installed"
  fi
else
  ok "NVM already installed"
fi

if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  # shellcheck disable=SC1090
  source "$NVM_DIR/nvm.sh"

  if nvm install "$NODE_VERSION"; then
    ok "Node $NODE_VERSION installed"
    nvm alias default "$NODE_VERSION" >/dev/null 2>&1 || true
  else
    fail "Could not install Node $NODE_VERSION through NVM"
  fi
else
  fail "NVM is unavailable; Node installation skipped"
fi

# ---------------------------------------------------------------------------
# Rust
# ---------------------------------------------------------------------------

section "Installing Rust"

if ! have rustup; then
  if have curl && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
    ok "Installed rustup"
  else
    fail "Could not install rustup"
  fi
else
  ok "rustup already installed"
fi

if [[ -s "$HOME/.cargo/env" ]]; then
  # shellcheck disable=SC1091
  source "$HOME/.cargo/env"
fi

if have rustup; then
  if rustup default stable; then
    ok "Rust stable toolchain configured"
  else
    fail "Could not configure Rust stable"
  fi

  if rustup component add rustfmt clippy; then
    ok "Installed rustfmt and clippy"
  else
    warn "Could not install one or more Rust components"
  fi
else
  fail "Rust toolchain setup skipped because rustup is unavailable"
fi

# Prefer rustup's rust-analyzer if available.
if have rustup; then
  rustup component add rust-analyzer >/dev/null 2>&1 || true
fi


# ---------------------------------------------------------------------------
# SDKMAN / JVM toolchain
# ---------------------------------------------------------------------------

section "Installing SDKMAN"

export SDKMAN_DIR="${SDKMAN_DIR:-$HOME/.sdkman}"

if [[ ! -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
  if have curl && curl -s "https://get.sdkman.io" | bash; then
    ok "Installed SDKMAN"
  else
    fail "Could not install SDKMAN"
  fi
else
  ok "SDKMAN already installed"
fi

if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
  patch_sdkman_shell_rcs
  source_sdkman

  section "Installing Java 25"

  if without_nounset sdk current java 2>/dev/null | grep -q "$JAVA_CANDIDATE"; then
    ok "Java $JAVA_CANDIDATE already active"
  else
    if without_nounset sdk install java "$JAVA_CANDIDATE"; then
      ok "Installed Java $JAVA_CANDIDATE"
    else
      fail "Could not install Java candidate '$JAVA_CANDIDATE'"
      warn "Run 'sdk list java' and choose an available Java 25 candidate"
    fi
  fi

  section "Installing Gradle"

  if have gradle; then
    ok "Gradle already available"
  elif without_nounset sdk install gradle; then
    ok "Installed Gradle"
  else
    fail "Could not install Gradle through SDKMAN"
  fi

  section "Installing Kotlin CLI"

  if have kotlinc; then
    ok "Kotlin compiler already available"
  elif without_nounset sdk install kotlin; then
    ok "Installed Kotlin through SDKMAN"
  else
    fail "Could not install Kotlin through SDKMAN"
  fi
else
  fail "SDKMAN is unavailable, so Java/Gradle/Kotlin SDKMAN installation was skipped"
fi

# ---------------------------------------------------------------------------
# Smoke tests
# ---------------------------------------------------------------------------

section "Creating and running smoke tests"

mkdir -p "$SMOKE_ROOT"

# Java
if have javac && have java; then
  mkdir -p "$SMOKE_ROOT/java-hello"
  cat > "$SMOKE_ROOT/java-hello/Main.java" <<'EOF'
public class Main {
    public static void main(String[] args) {
        System.out.println("Hello from Java " + Runtime.version());
    }
}
EOF

  if (
    cd "$SMOKE_ROOT/java-hello" &&
    javac Main.java &&
    java Main
  ); then
    ok "Java hello world"
  else
    fail "Java hello world failed"
  fi
else
  warn "Skipping Java smoke test: java/javac missing"
fi

# Go
if have go; then
  mkdir -p "$SMOKE_ROOT/go-hello"
  cat > "$SMOKE_ROOT/go-hello/main.go" <<'EOF'
package main

import "fmt"

func main() {
    fmt.Println("Hello from Go")
}
EOF

  if [[ ! -f "$SMOKE_ROOT/go-hello/go.mod" ]]; then
    (
      cd "$SMOKE_ROOT/go-hello" &&
      go mod init example.com/go-hello
    ) >/dev/null 2>&1 || true
  fi

  if (cd "$SMOKE_ROOT/go-hello" && go run .); then
    ok "Go hello world"
  else
    fail "Go hello world failed"
  fi
else
  warn "Skipping Go smoke test: go missing"
fi

# Node
if have node; then
  mkdir -p "$SMOKE_ROOT/node-hello"
  cat > "$SMOKE_ROOT/node-hello/index.js" <<'EOF'
console.log(`Hello from Node ${process.version}`);
EOF

  if (cd "$SMOKE_ROOT/node-hello" && node index.js); then
    ok "Node hello world"
  else
    fail "Node hello world failed"
  fi
else
  warn "Skipping Node smoke test: node missing"
fi

# Rust
if have cargo; then
  if [[ ! -f "$SMOKE_ROOT/rust-hello/Cargo.toml" ]]; then
    cargo new "$SMOKE_ROOT/rust-hello" --bin >/dev/null 2>&1 || true
  fi

  if [[ -f "$SMOKE_ROOT/rust-hello/Cargo.toml" ]] &&
     (cd "$SMOKE_ROOT/rust-hello" && cargo run); then
    ok "Rust hello world"
  else
    fail "Rust hello world failed"
  fi
else
  warn "Skipping Rust smoke test: cargo missing"
fi

# Odin
if have odin; then
  mkdir -p "$SMOKE_ROOT/odin-hello"
  cat > "$SMOKE_ROOT/odin-hello/main.odin" <<'EOF'
package main

import "core:fmt"

main :: proc() {
    fmt.println("Hello from Odin")
}
EOF

  if (cd "$SMOKE_ROOT/odin-hello" && odin run .); then
    ok "Odin hello world"
  else
    fail "Odin hello world failed"
  fi
else
  warn "Skipping Odin smoke test: odin missing"
fi

# Gradle + Java
if have gradle && have java; then
  mkdir -p "$SMOKE_ROOT/gradle-java/src/main/java"

  cat > "$SMOKE_ROOT/gradle-java/settings.gradle.kts" <<'EOF'
rootProject.name = "gradle-java"
EOF

  cat > "$SMOKE_ROOT/gradle-java/build.gradle.kts" <<'EOF'
plugins {
    application
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(25)
    }
}

application {
    mainClass = "Main"
}
EOF

  cat > "$SMOKE_ROOT/gradle-java/src/main/java/Main.java" <<'EOF'
public class Main {
    public static void main(String[] args) {
        System.out.println("Hello from Gradle + Java " + Runtime.version());
    }
}
EOF

  (
    cd "$SMOKE_ROOT/gradle-java"
    [[ -x ./gradlew ]] || gradle wrapper
  ) >/dev/null 2>&1 || true

  if [[ -x "$SMOKE_ROOT/gradle-java/gradlew" ]] &&
     (cd "$SMOKE_ROOT/gradle-java" && ./gradlew run); then
    ok "Gradle + Java hello world"
  else
    fail "Gradle + Java hello world failed"
  fi
else
  warn "Skipping Gradle + Java smoke test: Gradle/Java missing"
fi

# Gradle + Kotlin
if have gradle && have java; then
  mkdir -p "$SMOKE_ROOT/kotlin-hello/src/main/kotlin"

  cat > "$SMOKE_ROOT/kotlin-hello/settings.gradle.kts" <<'EOF'
rootProject.name = "kotlin-hello"
EOF

  cat > "$SMOKE_ROOT/kotlin-hello/build.gradle.kts" <<EOF
plugins {
    kotlin("jvm") version "${KOTLIN_PLUGIN_VERSION}"
    application
}

repositories {
    mavenCentral()
}

kotlin {
    jvmToolchain(25)
}

application {
    mainClass = "MainKt"
}
EOF

  cat > "$SMOKE_ROOT/kotlin-hello/src/main/kotlin/Main.kt" <<'EOF'
fun main() {
    println("Hello from Kotlin")
}
EOF

  (
    cd "$SMOKE_ROOT/kotlin-hello"
    [[ -x ./gradlew ]] || gradle wrapper
  ) >/dev/null 2>&1 || true

  if [[ -x "$SMOKE_ROOT/kotlin-hello/gradlew" ]] &&
     (cd "$SMOKE_ROOT/kotlin-hello" && ./gradlew run); then
    ok "Gradle + Kotlin hello world"
  else
    fail "Gradle + Kotlin hello world failed"
  fi
else
  warn "Skipping Kotlin Gradle smoke test: Gradle/Java missing"
fi

# Docker
if have docker; then
  mkdir -p "$SMOKE_ROOT/docker-hello"

  cat > "$SMOKE_ROOT/docker-hello/Dockerfile" <<'EOF'
FROM alpine:latest
CMD ["echo", "Hello from Docker"]
EOF

  if docker info >/dev/null 2>&1; then
    if (
      cd "$SMOKE_ROOT/docker-hello" &&
      docker build -q -t omarchy-hello . >/dev/null &&
      docker run --rm omarchy-hello
    ); then
      ok "Docker hello world"
    else
      fail "Docker hello world failed"
    fi
  else
    warn "Docker is installed but this session cannot use the socket yet"
    warn "If you were just added to the docker group, reboot and re-run. Until then: sudo docker ps"
  fi
else
  warn "Skipping Docker smoke test: docker missing"
fi

# ---------------------------------------------------------------------------
# Tool discovery
# ---------------------------------------------------------------------------

section "Installed tool versions"

show_version() {
  local tool="$1"
  shift

  if have "$tool"; then
    printf '\n--- %s ---\n' "$tool"
    "$@" 2>&1 | head -n 12 || true
  else
    printf '\n--- %s ---\nMISSING\n' "$tool"
  fi
}

show_version java java --version
show_version javac javac --version
show_version gradle gradle --version
show_version kotlinc kotlinc -version
show_version node node --version
show_version npm npm --version
show_version go go version
show_version gopls gopls version
show_version rustc rustc --version
show_version cargo cargo --version
show_version rust-analyzer rust-analyzer --version
show_version odin odin version
show_version docker docker --version
show_version nvim nvim --version
show_version pass pass version
show_version gpg gpg --version
show_version git git --version

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

printf '\n%b============================================================%b\n' "$blue" "$reset"
printf '%bBOOTSTRAP SUMMARY%b\n' "$blue" "$reset"
printf '%b============================================================%b\n\n' "$blue" "$reset"

printf '%bSuccessful / already configured: %d%b\n' "$green" "${#OK_ITEMS[@]}" "$reset"
for item in "${OK_ITEMS[@]}"; do
  printf '  ✓ %s\n' "$item"
done

if ((${#WARN_ITEMS[@]} > 0)); then
  printf '\n%bNeeds attention: %d%b\n' "$yellow" "${#WARN_ITEMS[@]}" "$reset"
  for item in "${WARN_ITEMS[@]}"; do
    printf '  ! %s\n' "$item"
  done
fi

if ((${#FAIL_ITEMS[@]} > 0)); then
  printf '\n%bFailed / missing: %d%b\n' "$red" "${#FAIL_ITEMS[@]}" "$reset"
  for item in "${FAIL_ITEMS[@]}"; do
    printf '  ✗ %s\n' "$item"
  done

  printf '\nThe bootstrap deliberately continued after these failures.\n'
  printf 'Fix the items above and simply run this script again.\n'
else
  printf '\n%bEverything the bootstrap attempted completed successfully.%b\n' "$green" "$reset"
fi

printf '\nSmoke-test workspace:\n  %s\n' "$SMOKE_ROOT"

printf '\nImportant next steps:\n'
printf '  1. Log out/in if Docker group membership was added.\n'
printf '  2. Restore SSH/GPG keys before cloning your password store.\n'
printf '  3. Run: pass ls\n'
printf '  4. Configure Neovim LSPs using NVIM-DEV-SETUP.md.\n'
printf '  5. Re-run this script after fixing anything reported above.\n\n'

# Intentionally return success so one missing optional developer tool does not
# turn the whole workstation bootstrap into a failure.
exit 0
