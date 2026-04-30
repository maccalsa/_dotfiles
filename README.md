# My Dotfiles

Ubuntu/Linux dotfiles for my shell, terminal, editor, CLI tools, language
toolchains, and development workflow.

The install is intentionally split into phases. Run the early phases first, open a
new shell when asked, then install heavier developer tooling.

## Quick Start

Clone the repo, then run commands from the repo root:

```bash
./bootstrap.sh
./zsh_setup.sh
```

Open a new terminal after `zsh_setup.sh`, then restore keys if this is a fresh
machine:

```bash
./backup/restore_keys.sh path/to/keys-backup.tar.gpg
```

Install the rest of the developer environment:

```bash
./install_software.sh
```

## Install Phases

1. `bootstrap.sh` installs base apt packages, fonts, Alacritty, and the Alacritty
   stow package.
2. `zsh_setup.sh` installs Zsh, Antidote, plugins, shell scripts, and Zsh config.
3. `backup/restore_keys.sh` restores SSH and GPG keys when setting up a fresh
   machine.
4. `install_software.sh` installs languages, tmux, fzf-git, Docker, Neovim,
   helper tools, Nix CLI tools, optionally Remmina/Cursor/Cursor CLI/snap/Telegram,
   then app config.
5. `post_install_software.sh` stows app configuration for tools that should be
   active after install.

## Important Notes

- This setup currently targets Ubuntu/Linux only.
- Run scripts from the repo root unless a script explicitly says otherwise.
- Restore SSH/GPG keys before installing the password store.
- Nix is kept for curated CLI tools and project dev shells. It is not used for
  everything.
- Espanso and bashhub are no longer part of the active setup.

## Documentation

- [Install pipeline](docs/install-pipeline.md)
- [Stow packages](docs/stow-packages.md)
- [Nix tools](docs/nix-tools.md)
- [Scripts package](stow/scripts/README.md)
- [Scripts structure](stow/scripts/STRUCTURE.md)
- [Neovim docs](stow/nvim/.config/nvim/README.md)

## Verification

After install, open a new shell and check:

```bash
zsh --version
stow --version
git --version
gh --version
docker --version
nvim --version
bat --version
tmux -V
ssh-add -l
gpg --list-secret-keys
nix --version
nix profile list
rustc --version
cargo --version
```
