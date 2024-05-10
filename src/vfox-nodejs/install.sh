#!/usr/bin/env bash

set -euxo pipefail

# Ensure script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Get variables from initial vfox install
# shellcheck disable=SC1091
source /etc/profile.d/vfox.sh

# Version is either specified or latest
export VERSION="${VERSION:-"latest"}"
# Prevent installers from trying to prompt for information
export DEBIAN_FRONTEND=noninteractive

# Check for vfox before proceeding
if ! command -v vfox &> /dev/null
then
    echo "vfox could not be found! I need vfox!"
    exit 1
fi

# Update packages
apt-get update && apt-get upgrade -y

# Install git to determine latest version if necessary
apt-get install -y git

# Add node plugin to vfox
vfox add nodejs
# Copy plugin to user directory
if [ "$VFOX_USER" != "root" ]
then
  cp --recursive /root/.version-fox/plugin "$VFOX_HOME"
fi

# Install node
vfox install "nodejs@${VERSION}"

# If version is "latest", find version number
if [ "$VERSION" == "latest" ]
then
    VERSION=$(vfox list nodejs |
        sed 's/[^0-9]*//' | # Remove everything before and including v
        sed 's/\s.*$//') # Delete everything after the first space
    export VERSION
fi

# Activate installed node version and add to .tool-versions file
vfox use --global "nodejs@${VERSION}"

# Activate vfox path helper for bash
eval "$(vfox activate bash)"
# Update npm
npm install --global npm@latest

# Copy .tool-versions to user directory
if [ "$VFOX_USER" != "root" ]
then
  cp /root/.version-fox/.tool-versions "$VFOX_HOME"
fi

# Ensure entire vfox directory is owned by user
if [ "$VFOX_USER" != "root" ]
then
  chown --recursive "${VFOX_USER}:" "$VFOX_HOME"
fi

echo 'Node.js installed!'
