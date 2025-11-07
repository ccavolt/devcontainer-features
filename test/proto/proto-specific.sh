#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "proto version" proto --version | grep "0.52.4"
check "PROTO_HOME variable exists" echo "${PROTO_HOME}" | grep "/opt/proto"
check "permissions" ls -la /opt/proto | grep "vscode"
check "users" cat /etc/passwd | grep "vscode"
check "shims is on path" echo "${PATH}" | grep "/opt/proto/shims"

# Report result
reportResults
