#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "vfox version" vfox --version
check "vfox_version script variable" cat /etc/profile.d/vfox.sh | grep 'export VFOX_VERSION='
check "vfox_user script variable" cat /etc/profile.d/vfox.sh | grep 'export VFOX_USER=root'
check "vfox_shell script variable" cat /etc/profile.d/vfox.sh | grep 'export VFOX_SHELL=bash'
# No expansion required
# shellcheck disable=SC2016
check "root user .bashrc vfox" cat /root/.bashrc | grep 'eval "$(vfox activate bash)"'
check "vfox sdks install location" vfox config --list | grep 'storage.sdkPath = /root/.version-fox/cache'
check "vfox config.yaml" cat /root/.version-fox/config.yaml | grep 'sdkPath: /root/.version-fox/cache'
check "vfox shims is on path" echo "$PATH" | grep '/root/.version-fox/shims'

# Report result
reportResults
