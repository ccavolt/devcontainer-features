#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "node.js version" node --version | grep "22.0.0"
check "npm version" npm --version
check "list vfox stuff" ls -la /home/vscode/.version-fox
check "Check for .tool-versions" cat /home/vscode/.version-fox/.tool-versions | grep "22.0.0"

# Report result
reportResults
