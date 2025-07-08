#!/bin/bash

set -e

PHX_VERSION="1.7.12"

echo "🚀 Installing Phoenix $PHX_VERSION generator..."
mix archive.install hex phx_new "$PHX_VERSION" --force


