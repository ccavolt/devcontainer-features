#!/usr/bin/env bash

set -euxo pipefail

# Ensure script is running as root
if [ "$(id -u)" -ne 0 ]; then
  echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
  exit 1
fi

# Get variables from initial vfox install
# shellcheck disable=SC1091
source /etc/profile.d/vfox.sh

# Version is either specified or latest
export VERSION="${VERSION:-"latest"}"
# Prevent installers from trying to prompt for information
export DEBIAN_FRONTEND=noninteractive
# Git Repo URL
export REPO="https://github.com/flutter/flutter.git"

# Check for vfox before proceeding
if ! command -v vfox &>/dev/null; then
  echo "vfox could not be found! I need vfox!"
  exit 1
fi

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

# Add flutter plugin to vfox
vfox add flutter
# Install flutter
vfox install "flutter@${VERSION}"
# Activate installed flutter version and add to .tool-versions file
vfox use --global "flutter@${VERSION}"

# Fix "dubious ownership" issue
git config --global --add safe.directory "/opt/vfox/flutter/v-${VERSION}/flutter-${VERSION}"

# Copy vfox stuff and ensure entire vfox home and cache directories are owned by user
if [ "$VFOX_USERNAME" != "root" ]; then
  cp --recursive /root/.version-fox "/home/${VFOX_USERNAME}"
  chown --recursive "${VFOX_USERNAME}:" "$VFOX_HOME"
  chown --recursive "${VFOX_USERNAME}:" "$VFOX_CACHE"
fi

echo 'Flutter installed!'
