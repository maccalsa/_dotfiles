#!/bin/bash

echo "We will now go throug the steps to install languages"

# Modify the prompts todefault to 'yes' if the user just presses Enter
read -p "Do you want to install go? (Y/n): " GO_INSTALL
GO_INSTALL=${GO_INSTALL:-y}

# "${BASH_SOURCE[0]}": This variable holds the path to the current script as it was invoked. It could be a relative or absolute path.
# dirname "...": This command extracts the directory part of the path.
# cd "...": This changes the directory to the script's directory.
# &> /dev/null: This suppresses any output from the cd command.
# pwd: This prints the present working directory (which is now the script's actual directory, resolved to an absolute path).
# $(...): This is command substitution, capturing the output of the commands inside.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"


if [ "$GO_INSTALL" = "y" ]; then
  # Install Go
  ${SCRIPT_DIR}/languages/go.sh
fi

read -p "Do you want to install python? (Y/n): " PYTHON_INSTALL
PYTHON_INSTALL=${PYTHON_INSTALL:-y}
if [ "$PYTHON_INSTALL" = "y" ]; then
  # Install Python
  ${SCRIPT_DIR}/languages/pyenv.sh
fi

read -p "Do you want to install node? (Y/n): " NODE_INSTALL
NODE_INSTALL=${NODE_INSTALL:-y}
if [ "$NODE_INSTALL" = "y" ]; then
  # Install Node
  ${SCRIPT_DIR}/languages/nvm.sh
fi

read -p "Do you want to install java and kotlin? (Y/n): " JAVA_INSTALL
JAVA_INSTALL=${JAVA_INSTALL:-y}
if [ "$JAVA_INSTALL" = "y" ]; then
  # Install Java
  ${SCRIPT_DIR}/languages/sdkman.sh
fi
