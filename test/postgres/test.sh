#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Start Postgres
service postgresql start

# Feature-specific tests
check "PostgreSQL Version" postgres -V | grep 15

# Report result
reportResults
