#!/usr/bin/env bash

set -eouvx pipefail

# Ensure script is running as root
if [ "$(id -u)" -ne 0 ]; then
  echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
  exit 1
fi

# Version is either specified or latest
export TRANSCRYPT_VERSION="${VERSION:-"latest"}"
# Git Repo URL
export REPO="https://github.com/elasticdog/transcrypt.git"
# Download directory
export DOWNLOADDIR=${HOME}/downloads
# Prevent installers from trying to prompt for information
export DEBIAN_FRONTEND=noninteractive

# Update packages
apt-get update && apt-get upgrade -y

# Install git to determine latest version if necessary
apt-get install -y git

# https://github.com/elasticdog/transcrypt/tags
# transcrypt version to install
if [ "${TRANSCRYPT_VERSION}" == "latest" ]; then
  TRANSCRYPT_VERSION=$(git -c 'versionsort.suffix=-' \
    ls-remote --exit-code --refs --sort='version:refname' --tags "${REPO}" '*.*.*' |
    grep -P "(/v)\d+(.)\d+(.)\d+$" | # Removes any non-conforming tags
    tail --lines=1 |                 # Remove all but last line
    cut --delimiter='/' --fields=3 | # Remove refs and tags sections
    sed 's/[^0-9]*//')               # Remove v character so there's only numbers and periods
  export TRANSCRYPT_VERSION
fi

# Create download directory
mkdir --parents "${DOWNLOADDIR}"

# Install transcrypt dependencies
apt-get install -y openssl bsdmainutils xxd gnupg
# Install wget to download transcrypt
apt-get install -y wget
# Create download directory
mkdir --parents "${DOWNLOADDIR}"
cd "${DOWNLOADDIR}"
# Download transcrypt and unzip
wget "https://github.com/elasticdog/transcrypt/archive/refs/tags/v${TRANSCRYPT_VERSION}.tar.gz"
tar -xzvf "v${TRANSCRYPT_VERSION}.tar.gz"
# Copy script to location on PATH
cd "transcrypt-${TRANSCRYPT_VERSION}"
cp transcrypt /usr/local/bin

echo 'Done!'
