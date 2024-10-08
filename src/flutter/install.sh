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
export REPO="https://github.com/flutter/flutter.git"
# Download directory
export DOWNLOAD_DIR=$HOME/downloads
# Install directory
export INSTALL_DIR=/opt
# Flutter directory
export FLUTTER_DIR="${INSTALL_DIR}/flutter"
# Flutter bin directory
export FLUTTER_BIN_DIR="${FLUTTER_DIR}/bin"
# Startup script location
export STARTUP_SCRIPT=/etc/profile.d/flutter.sh
touch $STARTUP_SCRIPT

# Update packages
apt-get update && apt-get upgrade -y

# Install git to determine latest version if necessary
apt-get install -y git

# https://github.com/flutter/flutter/tags
# Flutter version to install
if [ "$VERSION" == "latest" ]; then
  VERSION=$(git -c 'versionsort.suffix=-' \
    ls-remote --exit-code --refs --sort='version:refname' --tags "$REPO" '*.*.*' |
    grep -v "v" |                    # Exclude old versions that start with v
    grep -v "-" |                    # Exclude dev versions
    tail --lines=1 |                 # Only get the latest version
    cut --delimiter='/' --fields=3 | # Remove everything before version number (refs, tags, sha etc.)
    sed 's/[^0-9]*//')               # Remove anything before start of first number
  export VERSION
fi

# Flutter prereqs
apt-get install -y wget curl unzip xz-utils zip libglu1-mesa
# Prereqs for developing linux apps
apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev \
  liblzma-dev libstdc++-12-dev gnome-core mesa-utils chromium

# Clone flutter instead of downloading tarball to compile on Linux/arm64
# The flutter tool requires Git in order to operate properly
git clone --branch="$VERSION" $REPO $FLUTTER_DIR
# Fix "dubious ownership" issue
git config --global --add safe.directory "${FLUTTER_DIR}"
# Run tool to download necessary packages for arm64
${FLUTTER_BIN_DIR}/flutter

# Add to PATH
# Ensure $PATH isn't expanded, hence single quotes
# shellcheck disable=SC2016
echo "export PATH=${FLUTTER_BIN_DIR}:"'$PATH' >> $STARTUP_SCRIPT

# Ensure install directories are owned by user
if [ "$USERNAME" != "root" ]; then
  # Add user if necessary and create home folder
  adduser "$USERNAME" || echo "User already exists."
  mkdir -p "/home/${USERNAME}"

  # Set ownership to user
  chown --recursive "${USERNAME}:" "${FLUTTER_DIR}"
fi

echo 'Flutter installed!'
