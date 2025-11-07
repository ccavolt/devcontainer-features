#!/usr/bin/env bash

set -euxo pipefail

# Ensure script is running as root
if [ "$(id -u)" -ne 0 ]; then
  echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
  exit 1
fi

# Prevent installers from trying to prompt for information
export DEBIAN_FRONTEND=noninteractive
# Set username and create if it doesn't exist
export USERNAME="${USER:-"root"}"
if [ "${USERNAME}" != "root" ]; then
  export HOME="/home/${USERNAME}"
  useradd "${USERNAME}" || echo "User already exists."
  mkdir --parents "${HOME}"
  chown --recursive "${USERNAME}:${USERNAME}" "${HOME}"
fi

## Setup for packages
# Update packages
apt-get update && apt-get upgrade -y
# Install prereqs
apt-get install -y curl
# mkdir --parents /home/"${USERNAME}"/.local/bin/env
# Install UV
su --login "${USERNAME}" --command "curl -LsSf https://astral.sh/uv/install.sh | sh"
# curl -LsSf https://astral.sh/uv/install.sh | sh
# # Ensure all UV stuff is owned by specified user
# chown --recursive "${USERNAME}:${USERNAME}" "${HOME}"
# source "${HOME}"/.local/bin/env
# tree "${HOME}"/.local
# source "${HOME}"/.local/bin/env

ls -la "${HOME}"/.local/bin

# uv tool install pgcli --with psycopg-binary
su --login "${USERNAME}" --command "uv tool install pgcli --with psycopg-binary"

# ls -la "${HOME}"/.local/bin
# ls -la "${HOME}"/.local
# # exit 1

# cat /etc/passwd
# cat /etc/group

# chown --recursive "${USERNAME}:${USERNAME}:" "${HOME}"

# # Install pgcli
# if [ "${USERNAME}" != "root" ]; then
#   # Add user if necessary and create home folder
#   # tree /usr/sbin
#   # exit 1
#   # addgroup "${USERNAME}" --disabled-login || echo "User already exists."
#   # mkdir --parents "/home/${USERNAME}"/.local/bin/env
#   # tree /home/"${USERNAME}"/.local
#   # source /home/"${USERNAME}"/.local/bin/env
#   su --login "${USERNAME}" --command "uv tool install pgcli --with psycopg-binary"
# else
#   # source "${HOME}"/.local/bin/env
#   uv tool install pgcli --with psycopg-binary
# fi

echo 'Done!'
