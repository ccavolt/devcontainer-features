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
# Locale is either specified or en_US.UTF-8
export LOCALE="${LOCALE:-"en_US.UTF-8"}"
# Default mix commands are either specified or no
export DEFAULTMIXCOMMANDS="${DEFAULTMIXCOMMANDS:-"no"}"
# Prevent installers from trying to prompt for information
export DEBIAN_FRONTEND=noninteractive
# Git Repo URL
export REPO="https://github.com/elixir-lang/elixir.git"
# Set script location and create file
export SCRIPT=/etc/profile.d/vfox-elixir.sh
touch $SCRIPT

# Check for vfox before proceeding
if ! command -v vfox &> /dev/null
then
    echo "vfox could not be found! I need vfox!"
    exit 1
fi

# Update packages
apt-get update && apt-get upgrade -y

# Set locale for elixir
apt-get install -y locales
locale-gen "${LOCALE}"
export LANG="${LOCALE}"
echo "export LANG=${LOCALE}" >> $SCRIPT

# vfox elixir prereqs (Install inotify-tools filesystem watcher for live reloading to work)
apt-get install -y unzip inotify-tools

# Install git to determine latest version if necessary
apt-get install -y git

# https://github.com/elixir-lang/elixir/tags
# Elixir version to install
if [ "$VERSION" == "latest" ]
then
    VERSION=$(git -c 'versionsort.suffix=-' \
        ls-remote --exit-code --refs --sort='version:refname' --tags "$REPO" '*.*.*' |
        grep -v "rc" | # Exclude release candidates
        tail --lines=1 | # Only get the latest version
        cut --delimiter='/' --fields=3 | # Remove everything before version number (refs, tags, sha etc.)
        sed 's/[^0-9]*//') # Remove anything before start of first number
    export VERSION
fi

# Activate vfox path helper for bash
eval "$(vfox activate bash)"
# Install elixir vfox plugin
vfox add elixir
# Copy plugin to user directory
if [ "$VFOX_USER" != "root" ]
then
  cp --recursive /root/.version-fox/plugin "$VFOX_HOME"
fi

# Install elixir
vfox install "elixir@${VERSION}"
# Activate installed elixir version and add to .tool-versions file
vfox use --global "elixir@${VERSION}"

# Setup default mix commands (They are run after adding new Elixir version)
if [ "${DEFAULTMIXCOMMANDS}" == "yes" ]; then
    # Refresh vfox path helper after installing elixir
    eval "$(vfox activate bash)"
    # Install Hex Package Manager
    mix local.hex --force
    # Install rebar3 to build Erlang dependencies
    mix local.rebar --force
    # Install Phoenix Framework Application Generator
    mix archive.install hex phx_new --force
fi

# Copy .tool-versions and shims to user directory
if [ "$VFOX_USER" != "root" ]
then
  cp /root/.version-fox/.tool-versions "$VFOX_HOME"
  cp --recursive /root/.version-fox/shims "$VFOX_HOME"
fi

# Ensure entire vfox directory is owned by user
if [ "$VFOX_USER" != "root" ]
then
  chown --recursive "${VFOX_USER}:" "$VFOX_HOME"
fi

echo 'Elixir installed!'
