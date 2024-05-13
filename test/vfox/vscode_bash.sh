#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "vfox Version" vfox --version
check "vfox_version script variable" cat /etc/profile.d/vfox.sh | grep 'export VFOX_VERSION='
check "VFOX_USERNAME script variable" cat /etc/profile.d/vfox.sh | grep 'export VFOX_USERNAME=vscode'
check "vfox_shell script variable" cat /etc/profile.d/vfox.sh | grep 'export VFOX_SHELL=bash'
# No expansion required
# shellcheck disable=SC2016
check "vscode user .bashrc vfox" cat /home/vscode/.bashrc | grep 'eval "$(vfox activate bash)"'
check "vfox directory contents" ls -la /home/vscode/.version-fox
check "vfox shims is on path" echo "$PATH" | grep '/home/vscode/.version-fox/shims'
check "vfox sdks install location" vfox config --list | grep 'storage.sdkPath = /opt/vfox'

# Report result
reportResults
