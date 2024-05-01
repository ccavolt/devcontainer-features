#!/usr/bin/env bash

set -euxo pipefail

# Copy zsh config to user dir
cp .devcontainer/.zshrc "${HOME}"

# Update NPM
npm install -g npm@latest

# Install devcontainer cli
# https://github.com/devcontainers/cli/tags
npm install -g @devcontainers/cli@0.59.1

# this will add hover annotations in shell script files, assuming mads-hartmann.bash-ide-vscode is installed
docker container run --name explainshell --restart always -p 5000:5000 -d spaceinvaderone/explainshell
