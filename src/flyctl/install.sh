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
export REPO="https://github.com/superfly/flyctl.git"
# Download directory
export DOWNLOAD_DIR=$HOME/downloads
# Install directory
export INSTALL_DIR=/usr/local/bin/

# Update packages
apt-get update && apt-get upgrade -y

# Install git to determine latest version if necessary
apt-get install -y git

function validate_url() {
  if wget -S --spider "$1" 2>&1 | grep -q 'HTTP/1.1 200 OK'; then
    return 0
  else
    return 1
  fi
}

# https://github.com/superfly/flyctl/tags
# flyctl version to install
if [ "$VERSION" == "latest" ]; then
  VERSION=$(git -c 'versionsort.suffix=-' \
    ls-remote --exit-code --refs --sort='version:refname' --tags "$REPO" '*.*.*' |
    grep -P "(/v)\d{1,3}(.)\d+(.)\d+$" | # Removes major version year (e.g. v2023) builds that have no downloads available
    tail --lines=1 |                     # Remove all but last line
    cut --delimiter='/' --fields=3 |     # Remove refs and tags sections
    sed 's/[^0-9]*//')                   # Remove v character so there's only numbers and periods
  ENDPOINT="https://github.com/superfly/flyctl/releases/download/v${VERSION}/flyctl_${VERSION}_Linux_x86_64.tar.gz"
  if validate_url "$ENDPOINT"; then
    export VERSION
  else
    VERSION=$(git -c 'versionsort.suffix=-' \
      ls-remote --exit-code --refs --sort='version:refname' --tags "$REPO" '*.*.*' |
      grep -P "(/v)\d{1,3}(.)\d+(.)\d+$" | # Removes major version year (e.g. v2023) builds that have no downloads available
      tail --lines=2 |                     # Remove all but last 2 lines
      head --lines=1 |                     # Remove all but first line
      cut --delimiter='/' --fields=3 |     # Remove refs and tags sections
      sed 's/[^0-9]*//')                   # Remove v character so there's only numbers and periods
    export VERSION
  fi
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

# Download
wget --directory-prefix="$DOWNLOAD_DIR" "https://github.com/superfly/flyctl/releases/download/v${VERSION}/flyctl_${VERSION}_Linux_${ARCH}.tar.gz"
# Extract (-xzf)
tar --gzip --extract --file "${DOWNLOAD_DIR}/flyctl_${VERSION}_Linux_${ARCH}.tar.gz" -C $INSTALL_DIR

echo 'flyctl installed!'
