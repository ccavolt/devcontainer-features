#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "elixir" elixir --version | grep 1.17.1
check "locale" locale | grep "LANG=en_US.UTF-8"
check "hex" mix hex.info
check "check for hex" ls -la /home/vscode/.mix/archives | grep hex
check "check for phx_new" ls -la /home/vscode/.mix/archives | grep phx_new
check "check for igniter_new" ls -la /home/vscode/.mix/archives | grep igniter_new
check "check for rebar" ls -la /home/vscode/.mix/elixir/1-17 | grep rebar3

# Report result
reportResults
