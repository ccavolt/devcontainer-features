#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "Flutter version" flutter --version | grep "3.24.1"
check "Dart version" flutter --version | grep "3.5.1"
check "Check for flutter .tool-versions" cat /home/vscode/.version-fox/.tool-versions | grep "3.24.1"
check "Check for dart .tool-versions" cat /home/vscode/.version-fox/.tool-versions | grep "3.5.1"

# Report result
reportResults
