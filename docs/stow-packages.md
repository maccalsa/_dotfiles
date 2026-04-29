# Stow Packages

GNU Stow symlinks files from `stow/<package>` into `$HOME`.

Use this form from the repo root:

```bash
stow --dir=stow --target="$HOME" <package>
```

To remove a package:

```bash
stow --dir=stow --target="$HOME" --delete <package>
```

## Active Packages

| Package | Purpose | Installed by |
| --- | --- | --- |
| `alacritty` | Terminal config | `bootstrap.sh` |
| `bat` | `bat` theme/config | `post_install_software.sh` |
| `git` | Git config | `post_install_software.sh` |
| `nvim` | Neovim config | `post_install_software.sh` |
| `scripts` | Personal `x_` scripts and helper files | `zsh_setup.sh` |
| `tmux` | tmux config | `installers/install_tmux.sh` |
| `zshrc` | Zsh, Powerlevel10k, and SSH/GPG agent config | `zsh_setup.sh` |

## Manual Packages

| Package | Purpose | Notes |
| --- | --- | --- |
| `cursor` | Cursor user settings | Stow manually after installing Cursor if desired. |

## Removed Packages

Espanso and bashhub have been removed from the active setup. They were not useful
enough to keep installed by default.

## Config Ownership

Do not keep top-level `.config` files in the repo unless they are inside a stow
package. Files that should land in `~/.config` belong under the package that owns
them, for example `stow/zshrc/.config/secrets-agent.sh`.
