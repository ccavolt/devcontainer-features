#!/usr/bin/env bash

set -eouvx pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "transcrypt version" transcrypt --version

# Report result
reportResults
