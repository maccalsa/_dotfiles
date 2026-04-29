# Nix Tools

`nix/install_nix.sh` keeps Nix as a curated CLI tool installer for Ubuntu/Linux.
It does not replace every apt or language installer in this repo.

The script uses a flake reference, defaulting to:

```text
github:NixOS/nixpkgs/nixos-unstable
```

This keeps the CLI toolset modern and avoids the old Darwin channel mistake.

## Installed Tools

The curated list includes:

- Shell and navigation: `fzf`, `zoxide`, `direnv`, `nix-direnv`, `navi`, `atuin`
- File and text tools: `bat`, `eza`, `fd`, `ripgrep`, `sd`, `jq`, `yq-go`
- Git and diffs: `gh`, `delta`, `difftastic`, `lazygit`
- Containers and Kubernetes: `lazydocker`, `kind`, `kubectl`, `kubernetes-helm`, `ctlptl`
- Developer workflow: `just`, `watchexec`, `hyperfine`, `tokei`, `gum`, `glow`, `tealdeer`
- System inspection: `bottom`, `dust`, `procs`, `lsof`, `viddy`, `mprocs`
- HTTP and runtimes: `httpie`, `xh`, `bun`
- Other utilities: `jsonnet`, `pay-respects`, `zip`

`pay-respects` is a modern command correction helper in the same general space as
`thefuck`.

## Rust

Rust is installed through `installers/languages/rust.sh` with `rustup`, not
through this Nix tool list. That keeps Rust toolchain switching under the normal
Rust workflow.

## Verification

After running the Nix installer, open a new shell and check:

```bash
nix --version
nix profile list
pay-respects --help
direnv version
just --version
```

If completions or PATH look wrong, check whether the Nix profile is loaded in the
current shell before reinstalling tools.
