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
export REPO="https://github.com/erlang/otp.git"

# Check for vfox before proceeding
if ! command -v vfox &> /dev/null
then
    echo "vfox could not be found! I need vfox!"
    exit 1
fi

# Update packages
apt-get update && apt-get upgrade -y

# vfox erlang prereqs
apt-get install -y build-essential autoconf m4 libncurses5-dev \
   libwxgtk3.0-gtk3-dev libwxgtk-webview3.0-gtk3-dev libgl1-mesa-dev \
   libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop \
   libxml2-utils libncurses-dev openjdk-11-jdk

# Install git to determine latest version if necessary
apt-get install -y git

# https://github.com/erlang/otp/tags
# Erlang version to install
if [ "$VERSION" == "latest" ]
then
    VERSION=$(git -c 'versionsort.suffix=-' \
        ls-remote --exit-code --refs --sort='version:refname' --tags "$REPO" '*.*' |
        grep -v "rc" | # Exclude release candidates
        tail --lines=1 | # Only get the latest version
        cut --delimiter='/' --fields=3 | # Remove everything before version number (refs, tags, sha etc.)
        sed 's/[^0-9]*//') # Remove anything before start of first number
    export VERSION
fi

# Install erlang vfox plugin
vfox add erlang
# Install erlang
vfox install "erlang@${VERSION}"
# Activate installed erlang version and add to .tool-versions file
vfox use --global "erlang@${VERSION}"

# Copy and ensure entire vfox directory is owned by user
if [ "$VFOX_USERNAME" != "root" ]
then
  cp --recursive /root/.version-fox "/home/${VFOX_USERNAME}"
  chown --recursive "${VFOX_USERNAME}:" "$VFOX_HOME"
fi

echo 'Erlang installed!'
