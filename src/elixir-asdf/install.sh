#!/bin/bash -i

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# https://github.com/asdf-vm/asdf/tags
if [ "${ASDFVERSION}" == "latest" ]; then
    ASDF="0.11.3"
else
    ASDF="${ASDFVERSION}"
fi
# https://github.com/erlang/otp/tags
ERLANG="${ERLANGVERSION:-"latest"}"
# https://github.com/elixir-lang/elixir/tags
# Compatibility between Erlang and Elixir versions:
# https://hexdocs.pm/elixir/1.14.4/compatibility-and-deprecations.html
ELIXIR="${ELIXIRVERSION:-"latest"}"

# Set Locale
LCL="${LOCALE:-"en_US.UTF-8"}"

# Update packages
apt-get update && apt-get upgrade -y

# Create EAPROFILE
export EAPROFILE=/etc/profile.d/elixir.sh
touch $EAPROFILE

# Set locale for elixir
apt-get install -y locales
locale-gen "${LCL}"
export LANG="${LCL}"
echo "export LANG=${LCL}" >> $EAPROFILE

# Install ASDF
apt-get install -y curl git
mkdir -p /opt/asdf
# Where ASDF will be installed
export ASDF_DIR=/opt/asdf
echo "export ASDF_DIR=/opt/asdf" >> $EAPROFILE
# Where ASDF will store plugins, versions, etc
export ASDF_DATA_DIR=/opt/asdf
echo "export ASDF_DATA_DIR=/opt/asdf" >> $EAPROFILE
# Clone ASDF repo
git clone https://github.com/asdf-vm/asdf.git /opt/asdf --branch "v${ASDF}"
# Add ASDF to PATH
export PATH=$ASDF_DIR/shims:$ASDF_DIR/bin:$PATH
echo "export PATH=\"${PATH}:${ASDF_DIR}/shims:${ASDF_DIR}/bin\"" >> $EAPROFILE
echo ". ${ASDF_DIR}/asdf.sh" >> $EAPROFILE
# Ensure ASDF is up to date (if version isn't specified)
if [ "${ASDFVERSION}" == "latest" ]; then
    asdf update
fi

# Install Erlang & Elixir ASDF plugins
asdf plugin-add erlang
asdf plugin-add elixir
# Ensure ASDF plugins are up to date
asdf plugin-update --all

# ASDF Erlang Prereqs
apt-get install -y build-essential autoconf m4 libncurses5-dev \
   libwxgtk3.0-gtk3-dev libwxgtk-webview3.0-gtk3-dev libgl1-mesa-dev \
   libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop \
   libxml2-utils libncurses-dev openjdk-11-jdk
# Install Erlang from ASDF and set global version
asdf install erlang "${ERLANG}"
asdf global erlang "${ERLANG}"

# ASDF Elixir Prereqs
apt-get install -y unzip
# Install Elixir from ASDF and set global version
asdf install elixir "${ELIXIR}"
asdf global elixir "${ELIXIR}"
# Install filesystem watcher for live reloading to work
apt-get install -y inotify-tools

# Setup default mix commands (They are run after adding new Elixir version)
if [ "${DEFAULTMIXCOMMANDS}" == "yes" ]; then
    # Install Hex Package Manager
    mix local.hex --force
    # Install rebar3 to build Erlang dependencies
    mix local.rebar --force
    # Install Phoenix Framework Application Generator
    mix archive.install hex phx_new --force
fi

echo 'Done!'
