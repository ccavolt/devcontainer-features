#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "erlang" erl -eval '{ok, Version} = file:read_file(filename:join([code:root_dir(), "releases", erlang:system_info(otp_release), "OTP_VERSION"])), io:fwrite(Version), halt().' -noshell
check "erlang docs" erl -eval 'erlang:display(shell_docs:get_doc(lists)), halt().' -noshell | grep "List processing functions."
check "locale" locale | grep "LANG=en_US.UTF-8"

# Report result
reportResults
