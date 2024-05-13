#!/usr/bin/env bash

set -euxo pipefail

# Ensure script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Create vfox script
export SCRIPT=/etc/profile.d/vfox.sh
touch $SCRIPT
# Version is either specified or latest
export VERSION="${VERSION:-"latest"}"
echo "export VFOX_VERSION=${VERSION}" >> $SCRIPT
# Username is either specified or root
export USERNAME="${USERNAME:-"root"}"
echo "export VFOX_USERNAME=${USERNAME}" >> $SCRIPT
# Set Shell
export SHELL="${SHELL:-"bash"}"
echo "export VFOX_SHELL=${SHELL}" >> $SCRIPT
# Prevent installers from trying to prompt for information
export DEBIAN_FRONTEND=noninteractive
# Git Repo URL
export REPO="https://github.com/version-fox/vfox.git"

# Setup non-root user
if [ "$USERNAME" != "root" ]
then
  # Add user if necessary
  adduser "$USERNAME" || echo "User already exists."
  # Create home folder
  export USERHOMEDIR="/home/${USERNAME}"
  mkdir -p "$USERHOMEDIR"
else
  export USERHOMEDIR="/root"
fi

# Update packages
apt-get update && apt-get upgrade -y

# Install git to determine latest version if necessary
apt-get install -y git

# https://github.com/version-fox/vfox/tags
# vfox version to install
if [ "$VERSION" == "latest" ]
then
    VERSION=$(git -c 'versionsort.suffix=-' \
        ls-remote --exit-code --refs --sort='version:refname' --tags "$REPO" '*.*.*' |
        grep -P "(/v)\d+(.)\d+(.)\d+$" | # Removes alpha/custombuild and non conforming tags
        tail --lines=1 | # Remove all but last line
        cut --delimiter='/' --fields=3 | # Remove refs and tags sections
        sed 's/[^0-9]*//') # Remove v character so there's only numbers and periods
    export VERSION
fi

# Install prereqs
apt-get install -y curl gpg lsb-release apt-utils
# Create the repository configuration file
echo "deb [trusted=yes] https://apt.fury.io/versionfox/ /" | tee /etc/apt/sources.list.d/versionfox.list
# Install vfox
apt-get update
apt-get install -y vfox="${VERSION}"

# Set vfox variables
export VFOX_HOME=${USERHOMEDIR}/.version-fox
echo "export VFOX_HOME=${USERHOMEDIR}/.version-fox" >> $SCRIPT
# Add shims directory to path
# Ensure path isn't expanded, hence single quotes
# shellcheck disable=SC2016
echo 'export PATH=$PATH:'"${VFOX_HOME}/shims" >> $SCRIPT

# Hook vfox into user-selected user/shell combo
if [ "$SHELL" == "bash" ]
then
  touch "${USERHOMEDIR}/.bashrc"
  # No expansion required
  # shellcheck disable=SC2016
  echo 'eval "$(vfox activate bash)"' >> "${USERHOMEDIR}/.bashrc"
elif [ "$SHELL" == "fish" ]
then
  mkdir -p "${USERHOMEDIR}/.config/fish"
  touch "${USERHOMEDIR}/.config/fish/config.fish"
  echo 'vfox activate fish | source' >> "${USERHOMEDIR}/.config/fish/config.fish"
elif [ "$SHELL" == "zsh" ]
then
  touch "${USERHOMEDIR}/.zshrc"
  # No expansion required
  # shellcheck disable=SC2016
  echo 'eval "$(vfox activate zsh)"' >> "${USERHOMEDIR}/.zshrc"
else
  printf '%s\n' "Not a valid shell" >&2
  exit 1
fi

# Create vfox directory for root user, otherwise copy below will fail
mkdir /root/.version-fox
# Copy and ensure entire vfox directory is owned by user
if [ "$USERNAME" != "root" ]
then
  cp --recursive /root/.version-fox "${USERHOMEDIR}"
  chown --recursive "${USERNAME}:" "$VFOX_HOME"
fi

echo 'vfox installed!'
