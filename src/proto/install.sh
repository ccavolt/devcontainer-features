#!/usr/bin/env bash

set -euxo pipefail

# Ensure script is running as root
if [ "$(id -u)" -ne 0 ]; then
  echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
  exit 1
fi

# Username is either specified or root
export USERNAME="${USERNAME:-"root"}"
# Version is either specified or latest
export VERSION="${VERSION:-"latest"}"
# Prevent installers from trying to prompt for information
export DEBIAN_FRONTEND=noninteractive
# Git Repo URL
export REPO="https://github.com/moonrepo/proto"
# Download directory
export DOWNLOAD_DIR=$HOME/downloads
# Install directory
export INSTALL_DIR=/opt/proto
mkdir -p "$INSTALL_DIR"
# Startup script location
export STARTUP_SCRIPT=/etc/profile.d/proto.sh
touch $STARTUP_SCRIPT

# Update packages
apt-get update && apt-get upgrade -y

# Install git to determine latest version if necessary
apt-get install -y git

# https://github.com/moonrepo/proto/tags
# proto version to install
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
# Install dependencies
apt-get install -y wget unzip xz-utils
# Download proto
wget https://github.com/moonrepo/proto/releases/download/v"${VERSION}"/proto_cli-x86_64-unknown-linux-gnu.tar.xz
# Extract
tar --extract --file proto_cli-x86_64-unknown-linux-gnu.tar.xz
# Move binaries to install location
cd proto_cli-x86_64-unknown-linux-gnu
mv proto proto-shim "${INSTALL_DIR}"
# Enable execution permissions for binaries
chmod +x "${INSTALL_DIR}"/proto "${INSTALL_DIR}"/proto-shim

# Add to PATH and set PROTO_HOME
# Ensure $PATH isn't expanded, hence single quotes
# shellcheck disable=SC2016
echo "export PATH=${INSTALL_DIR}:"'$PATH' >> $STARTUP_SCRIPT
echo "export PROTO_HOME=${INSTALL_DIR}" >> $STARTUP_SCRIPT

# Ensure install directories are owned by user
if [ "$USERNAME" != "root" ]; then
  # Add user if necessary and create home folder
  adduser "$USERNAME" || echo "User already exists."
  mkdir -p "/home/${USERNAME}"

  # Set ownership to user
  chown --recursive "${USERNAME}:" "${INSTALL_DIR}"
fi

echo 'proto installed!'
