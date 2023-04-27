#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "asdf" asdf --version | grep 0.11.2
check "erlang" erl -eval '{ok, Version} = file:read_file(filename:join([code:root_dir(), "releases", erlang:system_info(otp_release), "OTP_VERSION"])), io:fwrite(Version), halt().' -noshell | grep 25.2
check "elixir" elixir --version | grep 1.14.3
check "path" echo "${PATH}"
check "locale" locale | grep en_US.UTF-8
check "hex" mix hex.info
check "Elixir Profile" cat /etc/profile.d/elxprofile.sh | grep LANG

# Report result
reportResults
