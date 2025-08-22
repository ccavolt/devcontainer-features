#!/usr/bin/env bash

set -eouvx pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "specstorycli version" specstory version
check "specstorycli help" specstory --help

# Report result
reportResults
