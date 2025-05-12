#!/bin/bash

set -e

echo "💡 Installing tools"

echo "💡 Installing git-helper"
go install github.com/EndlessUphill/git-helper@latest

echo "💡 Installing bashhub"
go install github.com/maccalsa/bashhub@latest

echo "💡 Tools installed successfully, try out git-helper with 'gh' and bashhub with 'bh'"

