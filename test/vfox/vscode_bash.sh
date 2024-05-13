#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "vfox Version" vfox --version
check "vfox_version script variable" cat /etc/profile.d/vfox.sh | grep 'export VFOX_VERSION='
check "vfox_user script variable" cat /etc/profile.d/vfox.sh | grep 'export VFOX_USER=vscode'
check "vfox_shell script variable" cat /etc/profile.d/vfox.sh | grep 'export VFOX_SHELL=bash'
# No expansion required
# shellcheck disable=SC2016
check "vscode user .bashrc vfox" cat /home/vscode/.bashrc | grep 'eval "$(vfox activate bash)"'
check "vfox sdks install location" vfox config --list | grep 'storage.sdkPath = /home/vscode/.version-fox/cache'
check "vfox directory contents" ls -la /home/vscode/.version-fox
check "vfox config.yaml" cat /home/vscode/.version-fox/config.yaml | grep 'sdkPath: /home/vscode/.version-fox/cache'
check "vfox shims is on path" echo "$PATH" | grep '/home/vscode/.version-fox/shims'

# Report result
reportResults
