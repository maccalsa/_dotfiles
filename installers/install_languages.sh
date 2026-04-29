#!/bin/bash

set -euo pipefail

echo "We will now go through the steps to install languages."

# "${BASH_SOURCE[0]}": This variable holds the path to the current script as it was invoked. It could be a relative or absolute path.
# dirname "...": This command extracts the directory part of the path.
# cd "...": This changes the directory to the script's directory.
# &> /dev/null: This suppresses any output from the cd command.
# pwd: This prints the present working directory (which is now the script's actual directory, resolved to an absolute path).
# $(...): This is command substitution, capturing the output of the commands inside.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

ask_yes_no() {
  local prompt="$1"
  local answer

  read -r -p "$prompt (Y/n): " answer
  answer=${answer:-y}
  [[ "$answer" =~ ^[Yy]$ ]]
}

if ask_yes_no "Do you want to install Go?"; then
  bash "${SCRIPT_DIR}/languages/go.sh"
fi

if ask_yes_no "Do you want to install Python?"; then
  bash "${SCRIPT_DIR}/languages/pyenv.sh"
fi

if ask_yes_no "Do you want to install Node?"; then
  bash "${SCRIPT_DIR}/languages/nvm.sh"
fi

if ask_yes_no "Do you want to install Java and Kotlin?"; then
  bash "${SCRIPT_DIR}/languages/sdkman.sh"
fi

if ask_yes_no "Do you want to install Rust?"; then
  bash "${SCRIPT_DIR}/languages/rust.sh"
fi

if ask_yes_no "Do you want to install Elixir and Erlang?"; then
  if ! command -v asdf >/dev/null 2>&1 && [ ! -x "$HOME/.asdf/bin/asdf" ]; then
    bash "${SCRIPT_DIR}/install_asdf.sh"
  fi

  # Make asdf available in this script even before the user opens a new shell.
  if [ -f "$HOME/.asdf/asdf.sh" ]; then
    # shellcheck disable=SC1091
    . "$HOME/.asdf/asdf.sh"
  fi

  bash "${SCRIPT_DIR}/languages/elixir_stack.sh"

  if ask_yes_no "Do you want to install the Phoenix generator?"; then
    bash "${SCRIPT_DIR}/languages/phoenix.sh"
  fi
fi
