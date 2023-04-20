#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# check "asdf" ${HOME}/.asdf/bin/asdf info
# check "erlang" erl --version
check "elixir" ${HOME}/.asdf/bin/asdf --version
check "bashrc" cat ~/.bashrc
check "path" echo $PATH
check "shell" echo "$SHELL"
check "whoami" which whoami

# Report result
reportResults