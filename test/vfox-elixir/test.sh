#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "elixir" elixir --version
check "locale" locale
check "vfox elixir script" cat /etc/profile.d/vfox-elixir.sh | grep LANG
check "check for toolversions file" cat /root/.version-fox/.tool-versions

# Report result
reportResults
