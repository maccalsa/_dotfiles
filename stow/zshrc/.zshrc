### ─── Powerlevel10k Instant Prompt ───────────────────────────────────────────
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

### ─── Core Environment Variables ─────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
export ZSH_DISABLE_COMPFIX="true"
export EDITOR="nvim"
export BAT_THEME="tokyonight_night"
export GOPRIVATE="github.com/EndlessUpHill/coesus"
export GIT_TERMINAL_PROMPT=0
export PNPM_HOME="$HOME/.local/share/pnpm"
export SDKMAN_DIR="$HOME/.sdkman"
export NVM_DIR="$HOME/.nvm"
export PYENV_ROOT="$HOME/.pyenv"
export GPG_TTY=$(tty)

### ─── PATH ────────────────────────────────────────────────────────────────────
path=(
  "$HOME/.local/bin"
  "/usr/local/go/bin"
  "$HOME/go/bin"
  "$HOME/.cargo/bin"
  "$PNPM_HOME"
  "$SDKMAN_DIR/candidates/java/current/bin"
  "$PYENV_ROOT/bin"
  "$NVM_DIR"
  $path
)

export PATH=$(printf "%s:" "${path[@]}")

### ─── Antidote ────────────────────────────────────────────────────────────────
source ~/.zsh/antidote/antidote.zsh
antidote load < ~/.zsh_plugins.txt

### ─── Powerlevel10k ──────────────────────────────────────────────────────────
export POWERLEVEL9K_MODE=nerdfont-complete
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

### ─── Git Prompt ─────────────────────────────────────────────────────────────
autoload -Uz vcs_info
precmd() { vcs_info }
setopt prompt_subst

### ─── Shell History ──────────────────────────────────────────────────────────
HISTFILE=$HOME/.zhistory
HISTSIZE=9999
SAVEHIST=9999
setopt share_history hist_expire_dups_first hist_ignore_dups hist_verify

### ─── Autocomplete ───────────────────────────────────────────────────────────
autoload -Uz compinit && compinit

### ─── FZF Configuration ──────────────────────────────────────────────────────
if command -v fzf &> /dev/null; then
  eval "$(fzf --zsh)"
  export FZF_DEFAULT_OPTS="
    --color=fg:#CBE0F0,bg:#011628,hl:#B388FF
    --color=fg+:#CBE0F0,bg+:#143652,hl+:#B388FF
    --color=info:#06BCE4,prompt:#2CF9ED,pointer:#2CF9ED,marker:#2CF9ED,spinner:#2CF9ED,header:#2CF9ED
  "
  export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"
  export FZF_CTRL_T_OPTS="--preview '[[ -d {} ]] && eza --tree --color=always {} | head -200 || bat -n --color=always --line-range :500 {}'"
  export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

  source ~/.fzf-git/fzf-git.sh
fi

### ─── Zoxide ─────────────────────────────────────────────────────────────────
command -v zoxide &>/dev/null && eval "$(zoxide init zsh --cmd cd)"

### ─── TheFuck ────────────────────────────────────────────────────────────────
command -v thefuck &>/dev/null && eval "$(thefuck --alias)"

### ─── pyenv ──────────────────────────────────────────────────────────────────
if command -v pyenv &>/dev/null; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi

### ─── nvm (Node) ─────────────────────────────────────────────────────────────
if [ -s "$NVM_DIR/nvm.sh" ]; then
  source "$NVM_DIR/nvm.sh"
  source "$NVM_DIR/bash_completion"
fi

### ─── SDKMAN ─────────────────────────────────────────────────────────────────
[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

### ─── Rust ───────────────────────────────────────────────────────────────────
[ -s "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

### ─── GPG & SSH Agent ────────────────────────────────────────────────────────
[[ -f ~/.config/secrets-agent.sh ]] && source ~/.config/secrets-agent.sh

### ─── eza ────────────────────────────────────────────────────────────────────
command -v eza &>/dev/null && alias ls="eza --icons=always"

### ─── Docker Compose ─────────────────────────────────────────────────────────
if command -v docker &>/dev/null; then
  mkdir -p ~/.zsh/completion
  fpath+=~/.zsh/completion
  alias dc='docker compose'
fi

### ─── Navi ───────────────────────────────────────────────────────────────────
command -v navi &>/dev/null && alias n='navi' nq='navi --query'

### ─── Lazygit ────────────────────────────────────────────────────────────────
command -v lazygit &>/dev/null && alias lg='lazygit'

### ─── Lazydocker ─────────────────────────────────────────────────────────────
command -v lazydocker &>/dev/null && alias ld='lazydocker'

### ─── Cursor ─────────────────────────────────────────────────────────────────
alias cursor='/opt/cursor.AppImage --no-sandbox'
