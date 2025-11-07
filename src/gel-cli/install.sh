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
apt-get install -y curl
# Install gel-cli (accept defaults so it's non-interactive)
curl https://www.geldata.com/sh --proto "=https" -sSf1 | sh -s -- -y

echo 'gel-cli installed!'
