#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "vfox Version" vfox --version
# No expansion required
# shellcheck disable=SC2016
check "root user .bashrc vfox" cat /root/.bashrc | grep 'eval "$(vfox activate bash)"'

# Report result
reportResults
