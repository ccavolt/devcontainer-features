#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# check "asdf" ${HOME}/.asdf/bin/asdf info
# check "erlang" erl --version
check "elixir" bash -c "${HOME}/.asdf/bin/asdf --version"

# Report result
reportResults