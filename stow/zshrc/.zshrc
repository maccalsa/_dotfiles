### ─── Powerlevel10k Instant Prompt ───────────────────────────────────────────
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

### ─── Core Environment Variables ─────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
export ZSH_DISABLE_COMPFIX="true"
export EDITOR=nvim
export BAT_THEME=tokyonight_night

export GOPRIVATE=github.com/EndlessUpHill/coesus
export GIT_TERMINAL_PROMPT=0
export PNPM_HOME="$HOME/.local/share/pnpm"
export SDKMAN_DIR="$HOME/.sdkman"
export NVM_DIR="$HOME/.nvm"
export PYENV_ROOT="$HOME/.pyenv"

### ─── Antidote ────────────────────────────────────────────────────────────────
source ~/.zsh/antidote/antidote.zsh
antidote load < ~/.zsh_plugins.txt

### ─── Powerlevel10k prompt (if configured) ───────────────────────────────────
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

### ─── Git ─────────────────────────────────────────────────────────────────────
autoload -Uz vcs_info
precmd() { vcs_info }
setopt prompt_subst

### ─── Autocomplete ───────────────────────────────────────────────────────────
autoload -Uz compinit && compinit

### ─── FZF Configuration ──────────────────────────────────────────────────────

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() { fd --hidden --exclude .git . "$1"; }

# Use fd to generate the list for directory completion
_fzf_compgen_dir() { fd --type=d --hidden --exclude .git . "$1"; }

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local cmd=$1; shift
  case "$cmd" in
    cd) fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo \${}'" "$@" ;;
    ssh) fzf --preview 'dig {}' "$@" ;;
    *) fzf --preview 'bat -n --color=always {}' "$@" ;;
  esac
}

if command -v fzf &> /dev/null; then
  eval "$(fzf --zsh)"

  # Theme
  fg="#CBE0F0"; bg="#011628"; bg_highlight="#143652"
  purple="#B388FF"; blue="#06BCE4"; cyan="#2CF9ED"

  export FZF_DEFAULT_OPTS="--color=fg:$fg,bg:$bg,hl:$purple,fg+:$fg,bg+:$bg_highlight,hl+:$purple,info:$blue,prompt:$cyan,pointer:$cyan,marker:$cyan,spinner:$cyan,header:$cyan"

  # Use fd with fzf
  export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

  # https://github.com/junegunn/fzf-git.sh
  # CTRL-G CTRL-F for Files
  # CTRL-G CTRL-B for Branches
  # CTRL-G CTRL-T for Tags
  # CTRL-G CTRL-R for Remotes
  # CTRL-G CTRL-H for commit Hashes
  # CTRL-G CTRL-S for Stashes
  # CTRL-G CTRL-L for reflogs
  # CTRL-G CTRL-W for Worktrees
  # CTRL-G CTRL-E for Each ref (git for-each-ref)
  source ~/.fzf/fzf-git.sh

  # FZF preview customization
  export FZF_CTRL_T_OPTS="--preview 'if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi'"
  export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"
fi

### ─── Shell History ──────────────────────────────────────────────────────────
HISTFILE=$HOME/.zhistory
HISTSIZE=9999
SAVEHIST=9999
setopt share_history hist_expire_dups_first hist_ignore_dups hist_verify

### ─── Tool Initializers ─────────────────────────────
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

### ─── Zoxide ─────────────────────────────────────────────────────────────────
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi

### ─── TheFuck ─────────────────────────────────────────────────────────────────
if command -v thefuck &> /dev/null; then
  eval "$(thefuck --alias)"
fi

### ─── Python ─────────────────────────────────────────────────────────────────
if command -v pyenv &> /dev/null; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi

### ─── Node ───────────────────────────────────────────────────────────────────
if command -v nvm &> /dev/null; then
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
fi

### ─── SDKMAN ──────────────────────────────────────────────────────────────────
if command -v sdk &> /dev/null; then
  export SDKMAN_DIR="$HOME/.sdkman"
  [ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
fi

### ─── go ─────────────────────────────────────────────────────────────────────
if command -v go &> /dev/null; then
  export PATH="$PATH:$(go env GOPATH)/bin"
fi

### ─── Rust ─────────────────────────────────────────────────────────────────────
if command -v rustup &> /dev/null; then
  source "$HOME/.cargo/env"
fi

### ─── pnpm ─────────────────────────────────────────────────────────────────────
if command -v pnpm &> /dev/null; then
  export PNPM_HOME="$HOME/.local/share/pnpm"
  export PATH="$PNPM_HOME:$PATH"
fi

### ─── GPG + SSH Agent ─────────────────────────────────────────────────────────

if command -v gpg &> /dev/null; then
  export GPG_TTY=$(tty)
  [[ -f ~/.config/secrets-agent.sh ]] && source ~/.config/secrets-agent.sh
fi

### ─── eza ───────────────────────────────────────────────────────────────────
if command -v eza &> /dev/null; then
  alias ls="eza --icons=always"
fi

# ### ─── Docker ───────────────────────────────────────────────────────────────────
# if command -v docker &> /dev/null; then
#   eval "$(docker-completion)"
# fi

### ─── Docker Compose ───────────────────────────────────────────────────────────
if command -v docker-compose &> /dev/null; then
   #   eval "$(docker-compose-completion)"
   alias dc="docker-compose"
fi

### ─── Navi ─────────────────────────────────────────────────────────────────────
if command -v navi &> /dev/null; then
  alias n='navi'
  alias nq='navi --query'
fi

### ─── Lazygit ───────────────────────────────────────────────────────────────────
if command -v lazygit &> /dev/null; then
  alias lg='lazygit'
fi

### ─── lazydocker ───────────────────────────────────────────────────────────────
if command -v lazydocker &> /dev/null; then
  alias ld='lazydocker'
fi

### ─── zoxide ───────────────────────────────────────────────────────────────────
if command -v zoxide &> /dev/null; then
  alias cd='z'
fi
