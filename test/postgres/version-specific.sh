#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Start Postgres
service postgresql start

# Feature-specific tests
check "PostgreSQL Version" postgres -V | grep 14
check "/etc/environment" cat /etc/environment | grep PGPROFILE
check "PGPROFILE File" cat /etc/profile.d/postgres.sh | grep PGDATA

# Report result
reportResults
