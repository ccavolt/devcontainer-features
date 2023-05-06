#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

apt install -y net-tools
service apache2 start

# Feature-specific tests
check "Apache (Runs pgadmin4) Status" netstat -anp | grep apache2

# Report result
reportResults
