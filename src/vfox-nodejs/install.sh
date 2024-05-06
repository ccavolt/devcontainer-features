#!/usr/bin/env bash

set -euxo pipefail

# Ensure script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Prevent installers from trying to prompt for information
export DEBIAN_FRONTEND=noninteractive
# Version is either specified or latest
export VERSION="${VERSION:-"latest"}"
# User is either specified or root
export USER="${USER:-"root"}"

# Update packages
apt-get update && apt-get upgrade -y

# Install git to determine latest version if necessary
apt-get install -y git

# Add node plugin to vfox
vfox add nodejs

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

# Activate installed node version and add to user .tool-versions file
vfox use --global "nodejs@${VERSION}"

# If not root, create user and home directory, copy vfox folder to user directory (if not root) and set ownership to user
if [ "${USER}" != "root" ]
then
    # Add user if they don't exist
    adduser "$USER" || echo "User already exists."
    # Create home directory for user
    mkdir -p "/home/${USER}"
    export USERDIR="/home/${USER}"
    # Copy .version-fox folder to user directory
    mkdir -p "/home/${USER}/.version-fox"
    cp --recursive "/root/.version-fox" "/home/${USER}/"
    # Set ownership to user
    chown --recursive "${USER}:" "/home/${USER}/.version-fox"
fi

echo 'Node.js installed!'
