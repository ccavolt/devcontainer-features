#!/usr/bin/env bash

set -euxo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# cat ${HOME}/.profile
# cat ${HOME}/.bashrc
# cat ${HOME}/.bash_profile
# cat ${HOME}/.zshrc
# cat ${HOME}/.zprofile
# source "${HOME}"/.local/bin/env

# # check where pgcli is installed
# check "where is pgcli" su --login vscode --command "pip3 show pgcli" | grep /home/vscode/.local/lib
# Check that pgcli can execute
# echo ${PATH}
check "pgcli version" su --login vscode --command "pgcli --version"
# check "pgcli version" pgcli --version
# Report result
reportResults
