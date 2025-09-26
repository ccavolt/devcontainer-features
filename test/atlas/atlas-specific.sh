#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "atlas version" atlas version | grep "0.36.0"
check "atlas help" atlas --help

# Report result
reportResults
