#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Idempotently start postgres
su --login "$PGUSER" --command "pg_ctl -D $PGDATA restart"

# Feature-specific tests
check "PostgreSQL Version" postgres -V | grep 14.8
check "PGDATA Exists" cat /etc/profile.d/postgres.sh | grep PGDATA
check "PGPASSWORD Exists" cat /etc/profile.d/postgres.sh | grep PGPASSWORD
check "Who owns postgres data" ls -la /opt/postgres/data | grep vscode
check "User Database Exists" su --login "$PGUSER" --command "psql -c \"select datname from pg_database;\"" | grep "$PGUSER"
check "Postgres encoding" su --login "$PGUSER" --command "psql -l" | grep "SQL_ASCII"

# Report result
reportResults
