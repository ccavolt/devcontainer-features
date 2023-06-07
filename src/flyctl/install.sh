#!/usr/bin/env bash

set -euxo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# https://github.com/superfly/flyctl/tags
# flyctl version
export FLYCTL_VERSION=${VERSION:-"0.1.27"}

# Create download directory
export DOWNLOADDIR=$HOME/downloads
mkdir $DOWNLOADDIR

# Update packages
apt-get update && apt-get upgrade -y

# Install CockroachDB dependencies
apt-get install -y wget

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

# Download flyctl and unzip
cd $DOWNLOADDIR
wget "https://github.com/superfly/flyctl/releases/download/v${FLYCTL_VERSION}/flyctl_${FLYCTL_VERSION}_${PLATFORM}_${ARCH}.tar.gz"
tar -xf "flyctl_${FLYCTL_VERSION}_${PLATFORM}_${ARCH}.tar.gz"
# Move flyctl Binary
mv flyctl /usr/local/bin/

echo 'Done!'
