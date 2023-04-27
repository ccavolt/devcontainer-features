#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Start Postgres
service postgresql start

# Feature-specific tests
check "PostgreSQL Version" postgres -V | grep 14
check "Dev Container Features File" cat /etc/profile.d/dcfeatures.sh | grep PGDATA

# Report result
reportResults
