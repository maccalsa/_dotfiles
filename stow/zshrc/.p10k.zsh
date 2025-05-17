# ~/.p10k.zsh - Improved readability and richer context
typeset -g POWERLEVEL9K_MODE=nerdfont-complete
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
typeset -g POWERLEVEL9K_INSTANT_PROMPT=off

# Prompt Elements
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  os_icon             # OS icon (nice visual)
  context             # User@host when SSH
  dir                 # Current directory
  vcs                 # Git branch/status
)

typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  status              # Exit status of last command
  command_execution_time
  node_version        # Node.js version
  go_version          # Golang version
  java_version        # Java version
  virtualenv          # Python .venv
  background_jobs
  time
)

# General Layout
#typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
#typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=""
#typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%F{blue}❯%f "

typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=""
typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX=""
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIVIS_FOREGROUND='076'
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIVIS_CONTENT_EXPANSION='❯'
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIVIS_CONTENT_EXPANSION='❯'

# Explicit Separators (Powerline symbols)
typeset -g POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR='\uE0B0'   # 
typeset -g POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR='\uE0B2'  # 

# Directory
typeset -g POWERLEVEL9K_DIR_FOREGROUND='white'
typeset -g POWERLEVEL9K_DIR_BACKGROUND='blue'
typeset -g POWERLEVEL9K_DIR_SHORTEN_STRATEGY="truncate_to_last"
typeset -g POWERLEVEL9K_DIR_SHORTEN_LENGTH=2

# Git (VCS)
typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND='black'
typeset -g POWERLEVEL9K_VCS_CLEAN_BACKGROUND='green'
typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND='black'
typeset -g POWERLEVEL9K_VCS_MODIFIED_BACKGROUND='yellow'

# Python Virtualenv
typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND='white'
typeset -g POWERLEVEL9K_VIRTUALENV_BACKGROUND='black'
typeset -g POWERLEVEL9K_VIRTUALENV_PREFIX='🐍 '

# Node.js Version
typeset -g POWERLEVEL9K_NODE_VERSION_FOREGROUND='black'
typeset -g POWERLEVEL9K_NODE_VERSION_BACKGROUND='green'
typeset -g POWERLEVEL9K_NODE_VERSION_PROJECT_ONLY=true
typeset -g POWERLEVEL9K_NODE_VERSION_PREFIX='󰎙 '

# Java Version
typeset -g POWERLEVEL9K_JAVA_VERSION_FOREGROUND='black'
typeset -g POWERLEVEL9K_JAVA_VERSION_BACKGROUND='red'
typeset -g POWERLEVEL9K_JAVA_VERSION_PROJECT_ONLY=true
typeset -g POWERLEVEL9K_JAVA_VERSION_PREFIX=' '

# Golang Version
typeset -g POWERLEVEL9K_GO_VERSION_FOREGROUND='black'
typeset -g POWERLEVEL9K_GO_VERSION_BACKGROUND='cyan'
typeset -g POWERLEVEL9K_GO_VERSION_PROJECT_ONLY=true
typeset -g POWERLEVEL9K_GO_VERSION_PREFIX=' '

# OS Icon
typeset -g POWERLEVEL9K_OS_ICON_FOREGROUND='white'
typeset -g POWERLEVEL9K_OS_ICON_BACKGROUND='black'

# Command Execution Time
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND='black'
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND='magenta'
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=2

# Status (Success/Error)
typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND='green'
typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND='red'
typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL=true

# Time
typeset -g POWERLEVEL9K_TIME_FOREGROUND='white'
typeset -g POWERLEVEL9K_TIME_BACKGROUND='black'
typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'

# Context (SSH session only)
typeset -g POWERLEVEL9K_CONTEXT_SSH_FOREGROUND='black'
typeset -g POWERLEVEL9K_CONTEXT_SSH_BACKGROUND='yellow'
typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE='%n@%m'

# do you want icons on all the time
# typeset -g POWERLEVEL9K_NODE_VERSION_PROJECT_ONLY=false
# typeset -g POWERLEVEL9K_JAVA_VERSION_PROJECT_ONLY=false
# typeset -g POWERLEVEL9K_GO_VERSION_PROJECT_ONLY=false
