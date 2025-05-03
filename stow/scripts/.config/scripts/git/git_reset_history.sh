#!/bin/bash

set -e

# Prompt for commit message
read -p "Enter commit message [Initial commit]: " COMMIT_MSG
COMMIT_MSG=${COMMIT_MSG:-"Initial commit"}

# Confirm destructive action
echo
echo "⚠️  This will DELETE all previous git commit history and FORCE PUSH a new commit to the remote."
read -p "Are you sure you want to continue? (y/N): " CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "Aborted."
  exit 1
fi

# Detect default remote branch name
DEFAULT_BRANCH=$(git remote show origin | grep 'HEAD branch' | awk '{print $NF}')
if [[ -z "$DEFAULT_BRANCH" ]]; then
  echo "❌ Unable to detect default branch. Exiting."
  exit 1
fi

echo "📦 Default remote branch detected: $DEFAULT_BRANCH"

# Create orphan branch
git checkout --orphan fresh-start

# Remove all tracked files without affecting untracked or .gitignored ones
git rm -rf --cached .
git clean -fdx

# If submodules exist, deinit them properly
if [ -f .gitmodules ]; then
  echo "🧹 Removing submodules..."
  git submodule deinit -f .
  rm -rf .git/modules/*
  git rm -f .gitmodules || true
fi

# Add only tracked files
git add .

# Make the new commit
git commit -m "$COMMIT_MSG"

# Delete old branch
git branch -D "$DEFAULT_BRANCH"

# Rename new branch
git branch -m "$DEFAULT_BRANCH"

# Force push to origin
git push -f origin "$DEFAULT_BRANCH"

echo
echo "✅ Git history has been reset and force pushed to origin/$DEFAULT_BRANCH."
echo "💡 Commit message: \"$COMMIT_MSG\""
