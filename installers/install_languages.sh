#!/bin/bash

echo "We will now go throug the steps to install languages"

# Modify the prompts todefault to 'yes' if the user just presses Enter
read -p "Do you want to install go? (Y/n): " GO_INSTALL
GO_INSTALL=${GO_INSTALL:-y}

if [ "$GO_INSTALL" = "y" ]; then
  # Install Go
  ./languages/go.sh
fi

read -p "Do you want to install python? (Y/n): " PYTHON_INSTALL
PYTHON_INSTALL=${PYTHON_INSTALL:-y}
if [ "$PYTHON_INSTALL" = "y" ]; then
  # Install Python
  ./languages/python.sh
fi

read -p "Do you want to install node? (Y/n): " NODE_INSTALL
NODE_INSTALL=${NODE_INSTALL:-y}
if [ "$NODE_INSTALL" = "y" ]; then
  # Install Node
  ./languages/node.sh
fi

read -p "Do you want to install java and kotlin? (Y/n): " JAVA_INSTALL
JAVA_INSTALL=${JAVA_INSTALL:-y}
if [ "$JAVA_INSTALL" = "y" ]; then
  # Install Java
  ./languages/java.sh
fi
