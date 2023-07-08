#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# check where pgcli is installed
check "where is pgcli" pip3 show pgcli | grep /root/.local/lib
# Check that pgcli can execute
check "pgcli version" pgcli --version

# Report result
reportResults
