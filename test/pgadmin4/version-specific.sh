#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "pgAdmin4 --version" pgAdmin4 --version | grep 6.21
check "pgAdmin --version" pgAdmin --version | grep 6.21

# Report result
reportResults
