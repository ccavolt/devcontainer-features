#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "erlang" erl -eval '{ok, Version} = file:read_file(filename:join([code:root_dir(), "releases", erlang:system_info(otp_release), "OTP_VERSION"])), io:fwrite(Version), halt().' -noshell
check "check for toolversions file" cat /root/.version-fox/.tool-versions
check "check for docs" erl -eval 'erlang:display(shell_docs:get_doc(lists)), halt().' -noshell | grep "List processing functions."

# Report result
reportResults
