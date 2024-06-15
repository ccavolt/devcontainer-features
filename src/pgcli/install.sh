#!/usr/bin/env bash

set -euxo pipefail

# Ensure script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Prevent installers from trying to prompt for information
export DEBIAN_FRONTEND=noninteractive
# Set Username
export PGUSER="${USER:-"root"}"
adduser "$PGUSER" || echo "User already exists."

# Update packages
apt-get update && apt-get upgrade -y

# Install prereqs
apt-get install -y python3-pip

# Install pgcli
if [ "$PGUSER" == "root" ]
then
  pip3 install "psycopg[binary,pool]" pgcli --break-system-packages
else
  su --login "$PGUSER" --command "pip3 install \"psycopg[binary,pool]\" pgcli --break-system-packages"
fi

echo 'Done!'
