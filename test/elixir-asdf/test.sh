#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "asdf" asdf --version
check "erlang" erl -eval '{ok, Version} = file:read_file(filename:join([code:root_dir(), "releases", erlang:system_info(otp_release), "OTP_VERSION"])), io:fwrite(Version), halt().' -noshell
check "elixir" elixir --version
check "path" echo $PATH
check "locale" locale
check "Elixir ASDF Script" cat /etc/profile.d/elixir-asdf.sh | grep LANG
check "check for toolversions file" cat /root/.tool-versions
check "ASDF installs dir permissions" ls -la /opt/asdf/installs

# Report result
reportResults
