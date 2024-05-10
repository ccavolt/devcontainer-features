#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "vfox Version" vfox --version | grep 0.4.1
check "vfox_version script variable" cat /etc/profile.d/vfox.sh | grep 'export VFOX_VERSION=0.4.1'
check "vfox_user script variable" cat /etc/profile.d/vfox.sh | grep 'export VFOX_USER=root'
check "vfox_shell script variable" cat /etc/profile.d/vfox.sh | grep 'export VFOX_SHELL=bash'
check "vfox config.yaml" cat /root/.version-fox/config.yaml | grep 'sdkPath: /root/.version-fox/cache'

# Report result
reportResults
