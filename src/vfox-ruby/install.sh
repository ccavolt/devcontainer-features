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
# Git Repo URL
export REPO="https://github.com/ruby/ruby.git"
# Prevent installers from trying to prompt for information
export DEBIAN_FRONTEND=noninteractive

# Check for vfox before proceeding
if ! command -v vfox &> /dev/null; then
  echo "vfox could not be found! I need vfox!"
  exit 1
fi

# Update packages
apt-get update && apt-get upgrade -y
# Install git to determine latest version if necessary
apt-get install -y git

# Install prereqs for building ruby
apt-get install -y autoconf patch build-essential rustc libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libgmp-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev uuid-dev
# Add ruby plugin to vfox
vfox add ruby

# If version is "latest", find version number
# https://github.com/ruby/ruby/tags
# Ruby version to install
if [ "$VERSION" == "latest" ]; then
  VERSION=$(git -c 'versionsort.suffix=-' \
    ls-remote --exit-code --refs --sort='version:refname' --tags "$REPO" '*_*_*' |
    grep -P "(/v)\d+(_)\d+(_)\d+$" | # Removes alpha/custombuild and non conforming tags
    tail --lines=1 |                 # Remove all but last line
    cut --delimiter='/' --fields=3 | # Remove refs and tags sections
    sed 's/[^0-9]*//' |              # Remove v character so there's only numbers and underscores
    sed 's/_/\./g')                  # Replaces _ with .
  export VERSION
fi

# Install ruby
vfox install "ruby@${VERSION}.rb"

# Activate installed ruby version which adds it to .tool-versions file
vfox use --global "ruby@${VERSION}"
# Activate vfox path helper for bash so that npm is accessible
eval "$(vfox activate bash)"
# Update RubyGems
gem update --system
# Upgrade Bundler
gem install bundler

# Copy vfox stuff and ensure entire vfox home and cache directories are owned by user
if [ "$VFOX_USERNAME" != "root" ]; then
  cp --recursive /root/.version-fox "/home/${VFOX_USERNAME}"
  chown --recursive "${VFOX_USERNAME}:" "$VFOX_HOME"
  chown --recursive "${VFOX_USERNAME}:" "$VFOX_CACHE"
fi

echo 'Ruby installed!'
