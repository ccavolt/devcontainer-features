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
export REPO="https://github.com/superfly/flyctl.git"
# Download directory
export DOWNLOADDIR=$HOME/downloads

# Update packages
apt-get update && apt-get upgrade -y

# Install git to determine latest version if necessary
apt-get install -y git

# https://github.com/superfly/flyctl/tags
# flyctl version to install
if [ -z "$VERSION" ] || [ "$VERSION" == "latest" ]
then
    FLYCTL_VERSION=$(git -c 'versionsort.suffix=-' \
        ls-remote --exit-code --refs --sort='version:refname' --tags "$REPO" '*.*.*' \
        | tail --lines=1 \
        | cut --delimiter='/' --fields=3 \
        | sed 's/[^0-9]*//')
    export FLYCTL_VERSION
else
    export FLYCTL_VERSION=$VERSION
fi

# Create download directory
mkdir -p "$DOWNLOADDIR"

# Determine platform
if [ "$(uname)" = "Linux" ]; then
    export PLATFORM="Linux"
elif [ "$(uname)" = "Darwin" ]; then
    export PLATFORM="macOS"
else
    echo -e 'Unsupported platform.'
    exit 1
fi

# Determine architecture
if [ "$(uname -m)" = "x86_64" ]; then
    export ARCH="x86_64"
elif [ "$(uname -m)" = "aarch64" ]; then
    export ARCH="arm64"
elif [ "$(uname -m)" = "arm64" ]; then
    export ARCH="arm64"
else
    echo -e 'Unsupported architecture.'
    exit 1
fi

# Install wget to download flyctl
apt-get install -y wget

# Download flyctl and unzip
cd "$DOWNLOADDIR"
wget "https://github.com/superfly/flyctl/releases/download/v${FLYCTL_VERSION}/flyctl_${FLYCTL_VERSION}_${PLATFORM}_${ARCH}.tar.gz"
tar -xf "flyctl_${FLYCTL_VERSION}_${PLATFORM}_${ARCH}.tar.gz"
# Move flyctl Binary
mv flyctl /usr/local/bin/

echo 'Done!'
