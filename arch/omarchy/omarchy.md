# Omarchy Neovim Development Setup

This guide assumes Omarchy's existing Neovim setup is already using **Lazy.nvim** and **Mason**. The aim is to extend what Omarchy provides rather than replace the whole configuration.

---

## Stow overlay

Omarchy already owns the desktop, LazyVim, tmux, and `~/.config/git/config`. Personal extras live in `arch/stow/` and are applied with GNU Stow. They add files Omarchy does not ship; they do not replace `init.lua`, `theme.lua`, `tmux.conf`, or the Omarchy git config.

Packages:

| Package | What it adds | What it leaves alone |
| --- | --- | --- |
| `git` | `~/.gitconfig` extra aliases, identity, `main` as default branch | `~/.config/git/config` |
| `nvim` | `lua/plugins/local-*.lua` plus language extras merged into `lazyvim.json` | LazyVim, theme hot-reload, Omarchy plugin files |
| `tmux` | `tmux.conf.local` plus a post-update hook that re-sources it | Omarchy prefix, theme, and keybinds |

Install stow if needed and apply:

```bash
./arch/omarchy/apply-stow.sh
```

Dry-run or remove:

```bash
./arch/omarchy/apply-stow.sh --dry-run
./arch/omarchy/apply-stow.sh --delete
```

`apply-stow.sh` also:

- installs `stow` via `omarchy pkg add stow` when missing
- takes ownership of root-owned trees under `~/.config/nvim`, `tmux`, and `git` so user-level stow can write
- replaces the Ubuntu `~/.gitconfig` symlink if it still points at `stow/git/`
- appends `source-file -q ~/.config/tmux/tmux.conf.local` to Omarchy's tmux.conf
- merges language extras into `~/.config/nvim/lazyvim.json` (the LazyVim-supported place; extras must not be imported from `lua/plugins/`)

After `omarchy refresh tmux`, re-run `apply-stow.sh` (or wait for the post-update hook) so the source-file line comes back.

Do not stow the Ubuntu packages (`alacritty`, `zshrc`, kickstart nvim) onto Omarchy.

IntelliJ navigation, format, errors, docs, and the move-a-function workflow: [intellij-shortcuts.md](intellij-shortcuts.md). Install with `./arch/omarchy/install-intellij.sh`.

Neovim (this LazyVim overlay): [nvim-shortcuts.md](nvim-shortcuts.md).

---

Languages covered:

- Odin
- Java 25+
- Kotlin
- Gradle
- Go
- Rust
- JavaScript / TypeScript
- Dockerfile / Compose / YAML / JSON

---

## 1. First inspect the existing Omarchy setup

Open Neovim and run:

```vim
:Lazy
:Mason
:checkhealth
```

From the shell:

```bash
find ~/.config/nvim -maxdepth 3 -type f | sort
```

Do not create a second, competing LSP stack if Omarchy already defines one.

---

## 2. Mason packages to install

Open:

```vim
:Mason
```

Install these where available:

```text
ols
jdtls
rust-analyzer
typescript-language-server
dockerfile-language-server
docker-compose-language-service
yaml-language-server
json-lsp
prettier
eslint_d
```

For Go, Omarchy already has access to the Arch `gopls` package if the bootstrap script was used:

```bash
gopls version
```

You can use Mason's `gopls` instead if you prefer all language servers to be Mason-managed.

For Kotlin, prefer the **official JetBrains Kotlin LSP** rather than the deprecated community Kotlin language server.

---

## 3. Treesitter parsers

With a normal nvim-treesitter setup:

```vim
:TSInstall java kotlin go gomod gosum rust javascript typescript tsx dockerfile json yaml
```

Odin support depends on the Treesitter version/plugin set in your Omarchy configuration. If `odin` is offered by `:TSInstallInfo`, install it too:

```vim
:TSInstall odin
```

---

## 4. Check whether LSPs attach

Neovim 0.11+ removed `:LspInfo`. On Omarchy (0.12) use:

```vim
:checkhealth vim.lsp
```

Or, in a real project file:

```vim
:lua vim.print(vim.lsp.get_clients({ bufnr = 0 }))
```

Fully quit and reopen Neovim after `apply-stow.sh` or Mason installs; an already-running session will not pick up new extras or servers.

Expected clients:

| Language | LSP |
|---|---|
| Odin | `ols` |
| Java | `jdtls` |
| Kotlin | `kotlin_lsp` |
| Go | `gopls` |
| Rust | `rust_analyzer` |
| JS / TS | `ts_ls` / TypeScript language server |
| Dockerfile | Dockerfile language server |
| Compose | Docker Compose language service |
| YAML | YAML language server |
| JSON | JSON language server |

Mason installing a binary does **not** by itself prove the LSP is attached.

---

# 5. Recommended native Neovim LSP configuration

Modern Neovim supports `vim.lsp.config()` and `vim.lsp.enable()`.

If your Omarchy config has a directory such as:

```text
~/.config/nvim/lua/plugins/
```

create something like:

```text
~/.config/nvim/lua/plugins/lsp-local.lua
```

Only do this if Omarchy is not already configuring the same servers.

Example:

```lua
return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      vim.lsp.enable({
        "gopls",
        "rust_analyzer",
        "ts_ls",
        "dockerls",
        "docker_compose_language_service",
        "yamlls",
        "jsonls",
        "ols",
        "jdtls",
      })

      vim.lsp.config("gopls", {
        settings = {
          gopls = {
            gofumpt = true,
            staticcheck = true,
          },
        },
      })

      vim.lsp.config("rust_analyzer", {
        settings = {
          ["rust-analyzer"] = {
            cargo = {
              allFeatures = true,
            },
            check = {
              command = "clippy",
            },
          },
        },
      })
    end,
  },
}
```

If Omarchy already manages these servers through Mason/Lazy extras, use its mechanism instead of duplicating this block.

---

# 6. Odin

Verify the compiler:

```bash
odin version
```

Verify OLS:

```bash
which ols
ols --version
```

Open:

```bash
cd ~/code/smoke-tests/odin-hello
nvim main.odin
```

Then:

```vim
:LspInfo
```

You want `ols` attached.

Useful tests:

- Put the cursor over `fmt.println` and press `K`.
- Type `fmt.` and check completion.
- Use `gd` on symbols.
- Rename a local symbol if your mappings provide LSP rename.

---

# 7. Java 25 + jdtls

Verify Java:

```bash
java --version
javac --version
```

Both should report Java 25 or newer.

Open:

```bash
cd ~/code/smoke-tests/gradle-java
nvim app/src/main/java/Main.java
```

Then:

```vim
:LspInfo
```

Expected:

```text
jdtls
```

Test completion:

```java
System.
```

Test hover:

```text
K
```

on `Runtime` or `System`.

## Important Java note

`jdtls` works best when Neovim is opened from the Gradle/Maven project root rather than directly against a random standalone `.java` file.

Prefer:

```bash
cd project-root
nvim .
```

over:

```bash
nvim /some/random/path/Main.java
```

---

# 8. Gradle

The Gradle wrapper should be the source of truth inside projects.

Verify:

```bash
gradle --version
./gradlew --version
```

For Java:

```bash
cd ~/code/smoke-tests/gradle-java
./gradlew run
```

For Kotlin:

```bash
cd ~/code/smoke-tests/kotlin-hello
./gradlew run
```

You do **not** need a special "Gradle LSP" for normal Java/Kotlin work.

The Java or Kotlin language server reads the Gradle project model.

Useful file support:

```text
build.gradle.kts
settings.gradle.kts
gradle.properties
libs.versions.toml
```

Treesitter handles syntax highlighting for Kotlin DSL files.

---

# 9. Kotlin — official JetBrains LSP

JetBrains now publishes the official `Kotlin/kotlin-lsp`.

The current Neovim integration supported by the project uses:

```lua
vim.lsp.enable("kotlin_lsp")

vim.lsp.config("kotlin_lsp", {
  single_file_support = false,
})
```

The `kotlin-lsp` executable must be on your `$PATH`.

## Check first

```bash
which kotlin-lsp
kotlin-lsp --version
```

If `kotlin-lsp` is not installed, download the standalone release from the official JetBrains Kotlin LSP repository and place/symlink its executable into:

```text
~/.local/bin
```

Ensure that directory is on your path:

```bash
mkdir -p ~/.local/bin
```

For zsh:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
```

Then reload:

```bash
source ~/.zshrc
```

## Neovim configuration

Add to the existing LSP configuration:

```lua
vim.lsp.config("kotlin_lsp", {
  single_file_support = false,
})

vim.lsp.enable("kotlin_lsp")
```

Open the Gradle project root:

```bash
cd ~/code/smoke-tests/kotlin-hello
nvim .
```

Open `src/main/kotlin/Main.kt` and run:

```vim
:LspInfo
```

Expected:

```text
kotlin_lsp
```

The official server understands JVM Gradle projects and provides completion, diagnostics, navigation, refactoring, formatting, hover documentation and imports.

---

# 10. Go

Verify:

```bash
go version
gopls version
```

Create/open:

```bash
cd ~/code/smoke-tests/go-hello
go mod init example.com/go-hello
nvim .
```

If you created `go.mod` after Neovim was already open, restart/reload the buffer.

Expected LSP:

```text
gopls
```

Recommended `gopls` settings:

```lua
vim.lsp.config("gopls", {
  settings = {
    gopls = {
      gofumpt = true,
      staticcheck = true,
      analyses = {
        unusedparams = true,
        unusedwrite = true,
      },
    },
  },
})

vim.lsp.enable("gopls")
```

Format a Go buffer using your normal LSP formatting mapping or:

```vim
:lua vim.lsp.buf.format()
```

---

# 11. Rust

Verify:

```bash
rustc --version
cargo --version
rust-analyzer --version
```

Open:

```bash
cd ~/code/smoke-tests/rust-hello
nvim .
```

Expected:

```text
rust_analyzer
```

Recommended settings:

```lua
vim.lsp.config("rust_analyzer", {
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        allFeatures = true,
      },
      check = {
        command = "clippy",
      },
    },
  },
})

vim.lsp.enable("rust_analyzer")
```

Test:

```rust
let value: String = String::
```

Completion should appear after `::`.

---

# 12. JavaScript / TypeScript / Node

Verify:

```bash
node --version
npm --version
```

For a TypeScript smoke test:

```bash
cd ~/code/smoke-tests/node-hello
npm install --save-dev typescript
printf 'const message: string = "Hello TypeScript";\nconsole.log(message);\n' > hello.ts
nvim .
```

Expected language server:

```text
ts_ls
```

Depending on your `nvim-lspconfig` version, the server name may differ from older examples online. Current configurations commonly use `ts_ls`.

Enable:

```lua
vim.lsp.enable("ts_ls")
```

For linting/formatting, Mason can install:

```text
prettier
eslint_d
```

Whether they are invoked automatically depends on the formatter/linter plugins Omarchy ships.

---

# 13. Docker

Docker itself is not a programming language. Neovim support is split by file type.

## Dockerfile

Server:

```text
dockerfile-language-server
```

Neovim name:

```text
dockerls
```

Configuration:

```lua
vim.lsp.enable("dockerls")
```

## Docker Compose

Server:

```text
docker-compose-language-service
```

Neovim name:

```text
docker_compose_language_service
```

Configuration:

```lua
vim.lsp.enable("docker_compose_language_service")
```

## YAML

For Compose and Kubernetes-like YAML:

```lua
vim.lsp.enable("yamlls")
```

## JSON

```lua
vim.lsp.enable("jsonls")
```

Smoke test:

```bash
mkdir -p ~/code/smoke-tests/docker-hello
cd ~/code/smoke-tests/docker-hello
```

Create:

```dockerfile
FROM alpine:latest
CMD ["echo", "Hello from Docker"]
```

Then:

```bash
docker build -t omarchy-hello .
docker run --rm omarchy-hello
```

---

# 14. Completion

Your existing Omarchy Lazy setup will probably already include a completion engine.

To identify it:

```vim
:Lazy
```

Look for one of:

```text
blink.cmp
nvim-cmp
```

Do not install a second completion engine.

LSP provides the completion data; Blink/CMP displays it.

---

# 15. Formatting

Before adding another formatting plugin, inspect `:Lazy`.

Common Omarchy/Lazy setups use something such as:

```text
conform.nvim
```

If it is already present, configure tools there rather than installing a second formatter system.

Typical formatters:

| Language | Formatter |
|---|---|
| Go | `gofmt` / `gofumpt` |
| Rust | `rustfmt` |
| Kotlin | official Kotlin LSP formatting |
| Java | `jdtls` formatting |
| JS/TS | `prettier` |
| JSON/YAML | `prettier` |
| Odin | `odinfmt` where available |

---

# 16. Diagnostics

Useful built-in commands:

```vim
:lua vim.diagnostic.open_float()
:lua vim.diagnostic.setloclist()
```

Common mappings in Lazy/Omarchy setups often include:

```text
[d
]d
```

for previous/next diagnostic.

Check the actual mappings with:

```vim
:map ]d
:map [d
```

---

# 17. Final verification checklist

Run these from the shell:

```bash
java --version
javac --version
gradle --version
kotlinc -version
node --version
npm --version
go version
gopls version
rustc --version
cargo --version
rust-analyzer --version
odin version
docker --version
nvim --version
pass version
```

Then open each smoke-test project and run `:LspInfo`.

Expected:

```text
~/code/smoke-tests/odin-hello       -> ols
~/code/smoke-tests/gradle-java      -> jdtls
~/code/smoke-tests/kotlin-hello     -> kotlin_lsp
~/code/smoke-tests/go-hello         -> gopls
~/code/smoke-tests/rust-hello       -> rust_analyzer
~/code/smoke-tests/node-hello       -> ts_ls
~/code/smoke-tests/docker-hello     -> dockerls
```

Once every row works, Neovim is ready for real projects.

---

# 18. Tool ownership

The intended setup is:

```text
Arch / pacman
├── Neovim
├── Git
├── GnuPG
├── pass
├── Docker
├── Go
├── gopls
├── Odin
└── base build tools

SDKMAN
├── Java 25+
├── Kotlin CLI
└── Gradle

NVM
└── Node LTS

rustup
├── Rust stable
├── Cargo
├── rustfmt
└── clippy

Mason / Neovim
├── OLS
├── jdtls
├── TypeScript LSP
├── Dockerfile LSP
├── Compose LSP
├── YAML LSP
└── JSON LSP

JetBrains
└── official Kotlin LSP
```

This keeps runtime/toolchain version management separate from editor tooling and avoids making pacman responsible for language versions you normally want to switch per project.