#!/usr/bin/env bash

set -euxo pipefail

# Update NPM
npm install -g npm@latest

# Install devcontainer cli
npm install -g @devcontainers/cli

# this will add hover annotations in shell script files, assuming mads-hartmann.bash-ide-vscod is installed
docker container run --name explainshell --restart always -p 5000:5000 -d spaceinvaderone/explainshell
