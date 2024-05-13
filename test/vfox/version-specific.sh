#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "vfox Version" vfox --version | grep 0.5.0
check "vfox_version script variable" cat /etc/profile.d/vfox.sh | grep 'export VFOX_VERSION=0.5.0'
check "VFOX_USERNAME script variable" cat /etc/profile.d/vfox.sh | grep 'export VFOX_USERNAME=root'
check "vfox_shell script variable" cat /etc/profile.d/vfox.sh | grep 'export VFOX_SHELL=bash'

# Report result
reportResults
