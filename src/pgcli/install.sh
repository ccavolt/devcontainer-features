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
# Install pgcli
su --login "${USERNAME}" --command "uv tool install pgcli --with psycopg-binary"

echo 'Done!'
