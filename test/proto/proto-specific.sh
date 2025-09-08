#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "proto version" proto --version | grep "0.52.4"
check "PROTO_HOME variable exists" echo "$PROTO_HOME" | grep "/opt/proto"

# Report result
reportResults
