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

# Add deno plugin to vfox
vfox add deno

# Install deno
vfox install "deno@${VERSION}"

# If version is "latest", find version number
if [ "$VERSION" == "latest" ]
then
    VERSION=$(vfox list deno |
        sed 's/[^0-9]*//' | # Remove everything before and including v
        sed 's/\s.*$//') # Delete everything after the first space
    export VERSION
fi

# Activate installed deno version and add to .tool-versions file
vfox use --global "deno@${VERSION}"

# Copy vfox stuff and ensure entire vfox home and cache directories are owned by user
if [ "$VFOX_USERNAME" != "root" ]
then
  cp --recursive /root/.version-fox "/home/${VFOX_USERNAME}"
  chown --recursive "${VFOX_USERNAME}:" "$VFOX_HOME"
  chown --recursive "${VFOX_USERNAME}:" "$VFOX_CACHE"
fi

echo 'Deno installed!'
