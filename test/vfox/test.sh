#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "vfox version" vfox --version
check "vfox_version script variable" cat /etc/profile.d/vfox.sh | grep 'export VFOX_VERSION='
check "vfox_username script variable" cat /etc/profile.d/vfox.sh | grep 'export VFOX_USERNAME=root'
check "vfox_shell script variable" cat /etc/profile.d/vfox.sh | grep 'export VFOX_SHELL=bash'
check "vfox shims is on path" echo "$PATH" | grep '/root/.version-fox/shims'

# Report result
reportResults
