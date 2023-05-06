#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Start CockroachDB
cockroach start-single-node \
  --http-addr=localhost:9999 \
  --insecure \
  --accept-sql-without-tls \
  --background \
  --log-config-file=./db/crdb-log-config.yaml

# Feature-specific tests
check "CockroachDB Version" cockroach version | grep "22.1.19"

# Report result
reportResults
