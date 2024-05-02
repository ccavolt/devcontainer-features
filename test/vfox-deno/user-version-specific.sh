#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "Deno version" deno --version | grep "1.42.4"
check "Check for .tools-version" cat /home/vscode/.version-fox/.tool-versions | grep "1.42.4"

# Report result
reportResults
