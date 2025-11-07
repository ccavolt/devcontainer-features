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
export REPO="https://github.com/specstoryai/getspecstory"
# Download directory
export DOWNLOAD_DIR=${HOME}/downloads

# Update packages
apt-get update && apt-get upgrade -y

# Install git to determine latest version if necessary
apt-get install -y git

# https://github.com/specstoryai/getspecstory/tags
# SpecStory CLI version to install
if [ "${VERSION}" == "latest" ]; then
  VERSION=$(git -c 'versionsort.suffix=-' \
    ls-remote --exit-code --refs --sort='version:refname' --tags "${REPO}" '*.*.*' |
    grep --invert-match "bbb5b6133eb15f0cf647581e54f265734d00f564" | # Removes erroneously named v1.0.0 by hash
    grep --perl-regexp "(/v)\d+(.)\d+(.)\d+$" |                      # Removes any non-conforming tags
    tail --lines=1 |                                                 # Remove all but last line
    cut --delimiter='/' --fields=3 |                                 # Remove refs and tags sections
    sed 's/[^0-9]*//')                                               # Remove v character so there's only numbers and periods
  export VERSION
fi

# Create download directory
mkdir --parents "${DOWNLOAD_DIR}"
cd "${DOWNLOAD_DIR}"
# Install dependencies to download and unzip SpecStory CLI
apt-get install -y wget unzip
# Download SpecStory CLI
wget https://github.com/specstoryai/getspecstory/releases/download/v"${VERSION}"/SpecStoryCLI_Linux_x86_64.zip
# Unzip SpecStory CLI
unzip SpecStoryCLI_Linux_x86_64.zip
# Move binary to /usr/local/bin
mv specstory /usr/local/bin/
# Enable execution permissions
chmod +x /usr/local/bin/specstory

echo 'SpecStory CLI installed!'
