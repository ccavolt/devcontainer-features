#!/usr/bin/env bash

set -euxo pipefail

# Ensure script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Prevent installers from trying to prompt for information
export DEBIAN_FRONTEND=noninteractive
# Git Repo URL
export REPO="https://github.com/version-fox/vfox.git"
# Set Username and add user if necessary
export USERNAME="${USER:-"root"}"
adduser "$USERNAME" || echo "User already exists."
# Set user directory
if [ "$USERNAME" != "root" ]
then
  mkdir -p "/home/${USERNAME}"
  export USERDIR="/home/${USERNAME}"
else
  export USERDIR="/root"
fi
# Set Shell
export SHELL="${SHELL:-"bash"}"

# Update packages
apt-get update && apt-get upgrade -y

# Install git to determine latest version if necessary
apt-get install -y git

# https://github.com/version-fox/vfox/tags
# vfox version to install
if [ -z "$VERSION" ] || [ "$VERSION" == "latest" ]
then
    VFOX_VERSION=$(git -c 'versionsort.suffix=-' \
        ls-remote --exit-code --refs --sort='version:refname' --tags "$REPO" '*.*.*' |
        grep -P "(/v)\d+(.)\d+(.)\d+$" | # Removes alpha/custombuild and non conforming tags
        tail --lines=1 | # Remove all but last line
        cut --delimiter='/' --fields=3 | # Remove refs and tags sections
        sed 's/[^0-9]*//') # Remove v character so there's only numbers and periods
    export VFOX_VERSION
else
    export VFOX_VERSION=${VERSION}
fi

# Install prereqs
apt-get install -y curl gpg lsb-release apt-utils
# Create the repository configuration file
echo "deb [trusted=yes] https://apt.fury.io/versionfox/ /" | tee /etc/apt/sources.list.d/versionfox.list
# Install vfox
apt-get update
apt-get install -y vfox="${VFOX_VERSION}"

# Hook vfox into shell
if [ "$SHELL" == "bash" ]
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