#!/usr/bin/env bash

set -euxo pipefail

# Ensure script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Prevent installers from trying to prompt for information
export DEBIAN_FRONTEND=noninteractive

# Update packages
apt-get update && apt-get upgrade -y

# Install prereqs
apt-get install -y curl gpg lsb-release apt-utils
# Import the EdgeDB packaging key
mkdir -p /usr/local/share/keyrings && \
curl --proto '=https' --tlsv1.2 -sSf \
  -o /usr/local/share/keyrings/edgedb-keyring.gpg \
  https://packages.edgedb.com/keys/edgedb-keyring.gpg
# Add the EdgeDB package repository
echo deb '[signed-by=/usr/local/share/keyrings/edgedb-keyring.gpg]'\
  https://packages.edgedb.com/apt \
  "$(grep "VERSION_CODENAME=" /etc/os-release | cut -d= -f2)" main \
  | tee /etc/apt/sources.list.d/edgedb.list
# Install the EdgeDB package
apt-get update
apt-get install -y edgedb-3

echo 'edgedb-cli installed!'
