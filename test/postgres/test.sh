#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Idempotently start postgres
su --login "$PGUSER" --command "pg_ctl -D $PGDATA restart"

# Feature-specific tests
check "PostgreSQL Version" postgres -V
check "PGDATA Exists" cat /etc/profile.d/postgres.sh | grep PGDATA
check "PGPASSWORD Exists" cat /etc/profile.d/postgres.sh | grep PGPASSWORD

# Report result
reportResults
