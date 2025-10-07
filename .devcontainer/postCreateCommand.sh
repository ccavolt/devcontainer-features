#!/usr/bin/env bash

set -eouvx pipefail

# Copy zsh config to user dir
cp .devcontainer/.zshrc "${HOME}"

# Update npm
npm install --global npm@latest

# Install devcontainer cli
# https://github.com/devcontainers/cli/tags
npm install --global @devcontainers/cli@0.80.1 \
  markdownlint-cli2 \
  prettier

# Remove explainshell after rebuild to prevent errors
docker rm --volumes --force "$(docker ps --all --quiet --filter ancestor=spaceinvaderone/explainshell)" || true
# This will add hover annotations in shell script files, assuming mads-hartmann.bash-ide-vscode is installed
docker container run --name explainshell --restart always -p 5000:5000 -d spaceinvaderone/explainshell
