#!/bin/bash

set -euo pipefail

echo "💡 Installing tools"

echo "💡 Installing git-helper"
go install github.com/EndlessUphill/git-helper@latest

echo "💡 Installing summarize-project-md"
npm install -g @maccalsa/summarize-project-md

echo "💡 Tools installed successfully. Try git-helper with 'gh'."

