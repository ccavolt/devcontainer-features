#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "Dart version" dart --version | grep "3.5.1"
check "Check for .tool-versions" cat /home/vscode/.version-fox/.tool-versions | grep "3.5.1"

# Report result
reportResults
