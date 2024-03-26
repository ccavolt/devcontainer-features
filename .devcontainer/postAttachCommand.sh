#!/usr/bin/env bash

set -eouvx pipefail

# Stuff to add if not running in a Codespace
# -z If string is empty (Opposite is -n)
# +variable_exists If $CODESPACES is null, nothing is substituted (Opposite is -)
# +variable_exists Prevents unbound variable error when $CODESPACES is null
if [ -z "${CODESPACES+variable_exists}" ]; then
  # Devcontainer detects dubious ownership; fix it
  git config --global --add safe.directory "${PROJECT_DIR}"

fi

# Add git hooks dir to git config
git config core.hooksPath .git-hooks
