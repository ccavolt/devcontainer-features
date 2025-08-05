#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "dotenvx help" dotenvx --help
check "dotenvx version" dotenvx --version

# Report result
reportResults
