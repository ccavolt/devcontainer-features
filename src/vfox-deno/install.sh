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
export REPO="https://github.com/denoland/deno.git"
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
    DENO_VERSION=$(git -c 'versionsort.suffix=-' \
        ls-remote --exit-code --refs --sort='version:refname' --tags "$REPO" '*.*.*' |
        grep -P "(/v)\d+(.)\d+(.)\d+$" | # Removes alpha/custombuild and non conforming tags
        tail --lines=1 | # Remove all but last line
        cut --delimiter='/' --fields=3 | # Remove refs and tags sections
        sed 's/[^0-9]*//') # Remove v character so there's only numbers and periods
    export DENO_VERSION
else
    export DENO_VERSION=${VERSION}
fi

# Add deno plugin
vfox add deno
# Install deno
vfox install "deno@${DENO_VERSION}"
# "Use" deno
vfox use -g "deno@${DENO_VERSION}"

# Copy vfox .tool-versions to user directory (if specified and not root) and set ownership to user
if [ "${USERNAME}" != "root" ]; then
    # Copy .tool-versions to user directory
    mkdir -p "/home/${USERNAME}/.version-fox"
    cp "/root/.version-fox/.tool-versions" "/home/${USERNAME}/.version-fox/.tool-versions"
    # Set ownership to user
    chmod 644 "/home/${USERNAME}/.version-fox/.tool-versions"
fi

echo 'Deno installed!'
