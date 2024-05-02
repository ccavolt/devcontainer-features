#!/usr/bin/env bash

set -euxo pipefail

# Ensure script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Prevent installers from trying to prompt for information
export DEBIAN_FRONTEND=noninteractive
# Git Repo URL
export REPO="https://github.com/nodejs/node.git"
# Set Username
export USERNAME="${USER:-"root"}"
adduser "$USERNAME" || echo "User already exists."
# Set user directory
if [ "$USERNAME" != "root" ]
then
  mkdir -p "/home/${USERNAME}"
  export USERDIR="/home/${USERNAME}"
fi

# Update packages
apt-get update && apt-get upgrade -y

# Install git to determine latest version if necessary
apt-get install -y git

# https://github.com/denoland/deno/tags
# Deno version to install
if [ -z "$VERSION" ] || [ "$VERSION" == "latest" ]
then
    NODE_VERSION=$(git -c 'versionsort.suffix=-' \
        ls-remote --exit-code --refs --sort='version:refname' --tags "$REPO" '*.*.*' |
        grep -P "(/v)\d+(.)\d+(.)\d+$" | # Removes alpha/custombuild and non conforming tags
        tail --lines=1 | # Remove all but last line
        cut --delimiter='/' --fields=3 | # Remove refs and tags sections
        sed 's/[^0-9]*//') # Remove v character so there's only numbers and periods
    export NODE_VERSION
else
    export NODE_VERSION=${VERSION}
fi

# Add node plugin
vfox add nodejs
# Install deno
vfox install "nodejs@${NODE_VERSION}"
# "Use" deno
vfox use -g "nodejs@${NODE_VERSION}"

# Copy vfox folder to user directory (if specified and not root) and set ownership to user
if [ "${USERNAME}" != "root" ]; then
    # Copy .version-fox folder to user directory
    mkdir -p "/home/${USERNAME}/.version-fox"
    cp --recursive "/root/.version-fox" "/home/${USERNAME}/"
    # Set ownership to user
    chown --recursive "${USERNAME}:" "/home/${USERNAME}/.version-fox"
fi

echo 'Node.js installed!'
