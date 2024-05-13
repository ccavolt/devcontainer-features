#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "vfox Version" vfox --version
check "vfox_version script variable" cat /etc/profile.d/vfox.sh | grep 'export VFOX_VERSION='
check "VFOX_USERNAME script variable" cat /etc/profile.d/vfox.sh | grep 'export VFOX_USERNAME=vscode'
check "vfox_shell script variable" cat /etc/profile.d/vfox.sh | grep 'export VFOX_SHELL=zsh'
# No expansion required
# shellcheck disable=SC2016
check "vscode user .zshrc vfox" cat /home/vscode/.zshrc | grep 'eval "$(vfox activate zsh)"'

# Report result
reportResults
