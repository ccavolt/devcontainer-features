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
vfox add ruby
# Install node
vfox install "ruby@${VERSION}"

# If version is "latest", find version number
if [ "$VERSION" == "latest" ]
then
    VERSION=$(vfox list ruby |
        sed 's/[^0-9]*//' | # Remove everything before and including v
        sed 's/\s.*$//' | # Delete everything after the first space
        sed 's/_/\./g') # Replaces _ with .
    export VERSION
fi

# Activate installed node version which adds it to .tool-versions file
vfox use --global "ruby@${VERSION}"
# Activate vfox path helper for bash so that npm is accessible
eval "$(vfox activate bash)"
# Update RubyGems
gem update --system
# Upgrade Bundler
gem install bundler

# Copy vfox stuff and ensure entire vfox home and cache directories are owned by user
if [ "$VFOX_USERNAME" != "root" ]
then
  cp --recursive /root/.version-fox "/home/${VFOX_USERNAME}"
  chown --recursive "${VFOX_USERNAME}:" "$VFOX_HOME"
  chown --recursive "${VFOX_USERNAME}:" "$VFOX_CACHE"
fi

echo 'Ruby installed!'
