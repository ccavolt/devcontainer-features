#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "asdf" asdf --version
check "erlang" erl -eval '{ok, Version} = file:read_file(filename:join([code:root_dir(), "releases", erlang:system_info(otp_release), "OTP_VERSION"])), io:fwrite(Version), halt().' -noshell
check "elixir" elixir --version
check "path" echo $PATH
check "profile" cat ${HOME}/.profile
check "locale" locale

# Report result
reportResults