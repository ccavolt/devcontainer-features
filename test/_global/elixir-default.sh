#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "elixir" elixir --version
check "locale" locale | grep "LANG=en_US.UTF-8"
check "hex" mix hex.info
check "check for hex" ls -la /root/.mix/archives | grep hex
check "check for phx_new" ls -la /root/.mix/archives | grep phx_new
check "check for igniter_new" ls -la /root/.mix/archives | grep igniter_new

# Report result
reportResults
