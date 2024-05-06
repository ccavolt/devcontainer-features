#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "elixir" elixir --version | grep 1.14.4
check "locale" locale | grep en_US.UTF-8
check "hex" mix hex.info
check "vfox elixir script" cat /etc/profile.d/vfox-elixir.sh | grep LANG
check "check for toolversions" cat /home/vscode/.version-fox/.tool-versions

# Report result
reportResults
