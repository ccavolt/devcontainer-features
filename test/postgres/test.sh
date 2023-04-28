#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Start Postgres
service postgresql start

# Feature-specific tests
check "PostgreSQL Version" postgres -V | grep 15
check "PGDATA Exists" cat /etc/profile.d/postgres.sh | grep PGDATA
check "PGPASSWORD Exists" cat /etc/profile.d/postgres.sh | grep PGPASSWORD

# Report result
reportResults
