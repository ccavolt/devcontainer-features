#!/usr/bin/env bash

set -euxo pipefail

# Ensure script is running as root
if [ "$(id -u)" -ne 0 ]; then
  echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
  exit 1
fi

# Version is either specified or latest
export VERSION="${VERSION:-"latest"}"
# Prevent installers from trying to prompt for information
export DEBIAN_FRONTEND=noninteractive
# Git Repo URL
export REPO="https://github.com/dotenvx/dotenvx"
# Download directory
export DOWNLOAD_DIR=$HOME/downloads

# Update packages
apt-get update && apt-get upgrade -y

# Install git to determine latest version if necessary
apt-get install -y git

# https://github.com/dotenvx/dotenvx/tags
# dotenvx version to install
if [ "$VERSION" == "latest" ]; then
  VERSION=$(git -c 'versionsort.suffix=-' \
    ls-remote --exit-code --refs --sort='version:refname' --tags "$REPO" '*.*.*' |
    grep --perl-regexp "(/v)\d+(.)\d+(.)\d+$" | # Removes any non-conforming tags
    tail --lines=1 |                            # Remove all but last line
    cut --delimiter='/' --fields=3 |            # Remove refs and tags sections
    sed 's/[^0-9]*//')                          # Remove v character so there's only numbers and periods
  export VERSION
fi

# Create download directory
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"
# Install dependencies to download dotenvx
apt-get install -y wget
# Download dotenvx
wget https://github.com/dotenvx/dotenvx/releases/download/v"${VERSION}"/dotenvx-"${VERSION}"-linux-x86_64.tar.gz
# Extract
tar --gzip --extract --file dotenvx-"${VERSION}"-linux-x86_64.tar.gz
# Move binary to /usr/local/bin
mv dotenvx /usr/local/bin/
# Enable execution permissions
chmod +x /usr/local/bin/dotenvx

echo 'dotenvx installed!'
