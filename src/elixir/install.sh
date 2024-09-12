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
# Locale
export LOCALE=en_US.UTF-8
# Git Repo URL
export REPO="https://github.com/elixir-lang/elixir.git"
# Download directory
export DOWNLOAD_DIR=$HOME/downloads
# Install directory
export INSTALL_DIR=/opt
# Elixir directory
export ELIXIR_DIR="${INSTALL_DIR}/elixir"
# Elixir bin directory
export ELIXIR_BIN_DIR="${ELIXIR_DIR}/bin"
# Startup script location
export STARTUP_SCRIPT=/etc/profile.d/elixir.sh
touch $STARTUP_SCRIPT

# Check for erlang before proceeding
erl -s erlang halt

# Update packages
apt-get update && apt-get upgrade -y

# Install git to determine latest version if necessary
apt-get install -y git

# https://github.com/elixir-lang/elixir/tags
# Elixir version to install
if [ "$VERSION" == "latest" ]; then
  VERSION=$(git -c 'versionsort.suffix=-' \
    ls-remote --exit-code --refs --sort='version:refname' --tags "$REPO" '*.*.*' |
    grep -v "rc" |                   # Exclude release candidates
    tail --lines=1 |                 # Only get the latest version
    cut --delimiter='/' --fields=3 | # Remove everything before version number (refs, tags, sha etc.)
    sed 's/[^0-9]*//')               # Remove anything before start of first number
  export VERSION
fi

# Set locale for elixir
apt-get install -y locales
echo "${LOCALE} UTF-8" >> /etc/locale.gen
locale-gen
export LANG="${LOCALE}"
echo "export LANG=${LOCALE}" >> $STARTUP_SCRIPT

# ## Install elixir
# # elixir prereqs (Install inotify-tools filesystem watcher for live reloading to work)
# apt-get install -y unzip inotify-tools
# # Download
# wget --directory-prefix="$DOWNLOAD_DIR" "https://github.com/elixir-lang/elixir/releases/download/v${VERSION}/elixir-otp-27.zip"
# # Extract
# unzip "${DOWNLOAD_DIR}/elixir-otp-27.zip" -d $ELIXIR_DIR
# ls -la $ELIXIR_BIN_DIR
# $ELIXIR_BIN_DIR/elixir --version
# $ELIXIR_BIN_DIR/iex

## Install elixir
# elixir prereqs (Install inotify-tools filesystem watcher for live reloading to work)
apt-get install -y unzip inotify-tools
# Download
wget --directory-prefix="$DOWNLOAD_DIR" "https://github.com/elixir-lang/elixir/archive/refs/tags/v${VERSION}.zip"
# Extract
unzip "${DOWNLOAD_DIR}/v${VERSION}.zip" -d $INSTALL_DIR
# Rename folder
mv "${INSTALL_DIR}/elixir-${VERSION}" $ELIXIR_DIR
cd $ELIXIR_DIR
make
cd ~

# Add to PATH
export PATH=$ELIXIR_BIN_DIR:$PATH
# Ensure $PATH isn't expanded, hence single quotes
# shellcheck disable=SC2016
echo "export PATH=${ELIXIR_BIN_DIR}:"'$PATH' >> $STARTUP_SCRIPT

## Setup default mix commands
# Ensure elixir and iex commands work
elixir --version
iex --version
# Install Hex Package Manager
mix local.hex --force
# Install rebar3 to build Erlang dependencies
mix local.rebar --force
# Install Phoenix Framework Application Generator
mix archive.install hex phx_new --force

# Ensure install directories are owned by user
if [ "$USERNAME" != "root" ]; then
  # Add user if necessary and create home folder
  adduser "$USERNAME" || echo "User already exists."
  mkdir -p "/home/${USERNAME}"

  # Copy mix stuff and ensure it's owned by user
  cp --recursive /root/.mix "/home/${USERNAME}"
  chown --recursive "${USERNAME}:" "/home/${USERNAME}/.mix"

  # Set ownership to user
  chown --recursive "${USERNAME}:" "${ELIXIR_DIR}"
fi

echo 'Elixir installed!'
