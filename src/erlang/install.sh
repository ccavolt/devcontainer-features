#!/usr/bin/env bash

set -euxo pipefail

# Ensure script is running as root
if [ "$(id -u)" -ne 0 ]; then
  echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
  exit 1
fi

# Locale is either specified or en_US.UTF-8
export LOCALE="${LOCALE:-"en_US.UTF-8"}"
# Username is either specified or root
export USERNAME="${USERNAME:-"root"}"
# Version is either specified or latest
export VERSION="${VERSION:-"latest"}"
# Prevent installers from trying to prompt for information
export DEBIAN_FRONTEND=noninteractive
# Git Repo URL
export REPO="https://github.com/erlang/otp.git"
# Download directory
export DOWNLOAD_DIR=$HOME/downloads
# Install directory
export INSTALL_DIR=/opt
# Erlang directory
# Uses ERL_TOP for building from source
export ERL_TOP="${INSTALL_DIR}/erlang"
# Increase make parallelism
export MAKEFLAGS=-j8
# Startup script location
export STARTUP_SCRIPT=/etc/profile.d/erlang.sh
touch $STARTUP_SCRIPT


# Update packages
apt-get update && apt-get upgrade -y

# Install git to determine latest version if necessary
apt-get install -y git wget

# https://github.com/erlang/otp/tags
# Erlang version to install
if [ "$VERSION" == "latest" ]; then
  VERSION=$(git -c 'versionsort.suffix=-' \
    ls-remote --exit-code --refs --sort='version:refname' --tags "$REPO" '*.*' |
    grep -v "rc" |                   # Exclude release candidates
    tail --lines=1 |                 # Only get the latest version
    cut --delimiter='/' --fields=3 | # Remove everything before version number (refs, tags, sha etc.)
    sed 's/[^0-9]*//')               # Remove anything before start of first number
  export VERSION
fi

# Install prereqs
apt-get install -y build-essential autoconf m4 libncurses5-dev \
  libwxgtk3.2-dev libwxgtk-webview3.2-dev libgl1-mesa-dev \
  libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop \
  libxml2-utils libncurses-dev openjdk-17-jdk
# Other prereqs
apt-get install -y make gcc clang perl sed

# Download
wget --directory-prefix="$DOWNLOAD_DIR" "https://github.com/erlang/otp/releases/download/OTP-${VERSION}/otp_src_${VERSION}.tar.gz"
# Extract -xzf
tar --gzip --extract --file "${DOWNLOAD_DIR}/otp_src_${VERSION}.tar.gz" -C $INSTALL_DIR
# Rename folder
mv "${INSTALL_DIR}/otp_src_${VERSION}" $ERL_TOP

# Simple OTP Build
$ERL_TOP/otp_build all

# ## Build and install erlang
# # Be in the source directory
# cd $ERL_TOP
# # Configure the build
# ./configure
# # Build
# make
# # Install
# make install

# ## Build and install docs
# # Ensure exdoc is installed
# ./otp_build download_ex_doc
# # Needed in path for building docs
# export PATH=$ERL_TOP/bin:$PATH
# # Build docs
# make docs
# # Install docs
# make install-docs

# # Add to PATH
# # Ensure $PATH isn't expanded, hence single quotes
# # shellcheck disable=SC2016
# echo "export PATH=${ERLANG_BIN_DIR}:"'$PATH' >>$STARTUP_SCRIPT

# Ensure install directories are owned by user
if [ "$USERNAME" != "root" ]; then
  # Add user if necessary and create home folder
  adduser "$USERNAME" || echo "User already exists."
  mkdir -p "/home/${USERNAME}"

  # Set ownership to user
  chown --recursive "${USERNAME}:" "${ERL_TOP}"
fi

echo 'Erlang installed!'
