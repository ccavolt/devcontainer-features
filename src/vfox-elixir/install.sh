#!/usr/bin/env bash

set -euxo pipefail

# Ensure script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Version is either specified or latest
export VERSION="${VERSION:-"latest"}"
# Locale is either specified or en_US.UTF-8
export LOCALE="${LOCALE:-"en_US.UTF-8"}"
# Default mix commands are either specified or no
export DEFAULTMIXCOMMANDS="${DEFAULTMIXCOMMANDS:-"no"}"
# User is either specified or root
export USER="${USER:-"root"}"
# Prevent installers from trying to prompt for information
export DEBIAN_FRONTEND=noninteractive
# Set script location and create file
export ELIXIR_SCRIPT=/etc/profile.d/vfox-elixir.sh
touch $ELIXIR_SCRIPT

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
echo "export LANG=${LOCALE}" >> $ELIXIR_SCRIPT

# vfox elixir prereqs (Install inotify-tools filesystem watcher for live reloading to work)
apt-get install -y unzip inotify-tools
# Install elixir vfox plugin
vfox add elixir
# Install elixir
vfox install "elixir@${VERSION}"
# If version is "latest", find version number
if [ "$VERSION" == "latest" ]
then
    VERSION=$(vfox list elixir |
        sed 's/[^0-9]*//' | # Remove everything before and including v
        sed 's/\s.*$//') # Delete everything after the first space
    export VERSION
fi
# Activate installed elixir version and add to .tool-versions file
vfox use --global "elixir@${VERSION}"

# Setup default mix commands (They are run after adding new Elixir version)
if [ "${DEFAULTMIXCOMMANDS}" == "yes" ]; then
    # Install Hex Package Manager
    mix local.hex --force
    # Install rebar3 to build Erlang dependencies
    mix local.rebar --force
    # Install Phoenix Framework Application Generator
    mix archive.install hex phx_new --force
fi

# If not root, create user and home directory, copy vfox folder to user directory (if not root) and set ownership to user
if [ "${USER}" != "root" ]
then
    # Add user if they don't exist
    adduser "$USER" || echo "User already exists."
    # Create home directory for user
    mkdir -p "/home/${USER}"
    export USERDIR="/home/${USER}"
    # Copy .version-fox folder to user directory
    mkdir -p "/home/${USER}/.version-fox"
    cp --recursive "/root/.version-fox" "/home/${USER}/"
    # Set ownership to user
    chown --recursive "${USER}:" "/home/${USER}/.version-fox"
fi

echo 'Elixir installed!'
