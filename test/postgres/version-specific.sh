#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Start Postgres
su --login "$PGUSER" --command "pg_ctl -D $PGDATA start"

# Feature-specific tests
check "PostgreSQL Version" postgres -V | grep 14.8
check "PGDATA Exists" cat /etc/profile.d/postgres.sh | grep PGDATA
check "PGPASSWORD Exists" cat /etc/profile.d/postgres.sh | grep PGPASSWORD
check "Who owns postgres data" ls /opt/postgres/data | grep vscode

# Report result
reportResults
