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
# User is either specified or root
export USER="${USER:-"root"}"
echo "export VFOX_USER=${USER}" >> $SCRIPT
# Set Shell
export SHELL="${SHELL:-"bash"}"
echo "export VFOX_SHELL=${SHELL}" >> $SCRIPT
# Prevent installers from trying to prompt for information
export DEBIAN_FRONTEND=noninteractive
# Git Repo URL
export REPO="https://github.com/version-fox/vfox.git"

# Add user if necessary
adduser "$USER" || echo "User already exists."
# Set user directory
if [ "$USER" != "root" ]
then
  mkdir -p "/home/${USER}"
  export USERDIR="/home/${USER}"
else
  export USERDIR="/root"
fi
# Add userdir to script
echo "export VFOX_USERDIR=${USERDIR}" >> $SCRIPT

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

# Hook vfox into root bash shell for installing languages later
# No expansion required
# shellcheck disable=SC2016
echo 'eval "$(vfox activate bash)"' >> /root/.bashrc
# Hook vfox into user-selected user/shell combo
if [ "$SHELL" == "bash" ] && [ "$USER" == "root" ]
then
  echo "vfox command already in place for root user bash"
elif [ "$SHELL" == "bash" ]
then
  touch "${USERDIR}/.bashrc"
  # No expansion required
  # shellcheck disable=SC2016
  echo 'eval "$(vfox activate bash)"' >> "${USERDIR}/.bashrc"
elif [ "$SHELL" == "fish" ]
then
  mkdir -p "${USERDIR}/.config/fish"
  touch "${USERDIR}/.config/fish/config.fish"
  echo 'vfox activate fish | source' >> "${USERDIR}/.config/fish/config.fish"
elif [ "$SHELL" == "zsh" ]
then
  touch "${USERDIR}/.zshrc"
  # No expansion required
  # shellcheck disable=SC2016
  echo 'eval "$(vfox activate zsh)"' >> "${USERDIR}/.zshrc"
else
  printf '%s\n' "Not a valid shell" >&2
  exit 1
fi

echo 'vfox installed!'
