# Install Pipeline

This repo targets Ubuntu/Linux. Run the scripts from the repo root.

## Recommended Order

1. `./bootstrap.sh`
   - Installs base apt packages.
   - Installs fonts.
   - Installs Alacritty.
   - Stows the Alacritty config.

2. `./zsh_setup.sh`
   - Installs Zsh and shell dependencies.
   - Installs Antidote.
   - Writes the Zsh plugin list.
   - Stows `scripts` and `zshrc`.
   - Offers to set Zsh as the default shell.

3. Open a new terminal.

4. Restore keys on fresh machines:

   ```bash
   ./backup/restore_keys.sh path/to/keys-backup.tar.gpg
   ```

5. `./install_software.sh`
   - Installs language toolchains.
   - Installs tmux and fzf-git.
   - Optionally installs `pass` and clones the password store.
   - Installs Docker and Neovim.
   - Installs curated Nix CLI tools.
   - Optionally installs desktop GUI stack: Remmina (apt), Cursor IDE (download +
     AppImage under `/opt`, `cursor` on `PATH`), Cursor CLI (`agent` via official
     install script), `snapd` + Telegram Desktop (`snap`).
   - Stows active app configs.

## Optional Installers

These are present but only run during `install_software.sh` when you confirm the
prompt, or run the script manually:

- `installers/install_desktop_apps.sh` — Remmina, Cursor, Cursor CLI, snap,
  Telegram; uses `install_cursor.sh` internally for the IDE AppImage.
- `installers/install_cursor.sh` — Cursor IDE only.
- `installers/install_dbeaver.sh`
- `installers/install_intellij.sh`
- `installers/languages/install_ada.sh`

Run optional installers directly only when you need them.

## Language Toolchains

`installers/install_languages.sh` prompts for:

- Go
- Python through pyenv
- Node through nvm
- Java and Kotlin through SDKMAN
- Rust through rustup
- Elixir and Erlang through asdf
- Phoenix after Elixir is installed

Ada is intentionally left manual until its installer is made idempotent.

## Removed From Active Setup

Espanso and bashhub are no longer installed or stowed. If they are needed again,
add them back deliberately with a working installer and documentation.

`installers/install_tools.sh` is kept for manual one-off use, but is no longer
part of the active `install_software.sh` flow.
