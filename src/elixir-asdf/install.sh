#!/usr/bin/env bash

set -euxo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# https://github.com/asdf-vm/asdf/tags
if [ "${ASDFVERSION}" == "latest" ]; then
    ASDF_VERSION="0.11.3"
else
    ASDF_VERSION="${ASDFVERSION}"
fi
# https://github.com/erlang/otp/tags
ERLANG_VERSION="${ERLANGVERSION:-"latest"}"
# https://github.com/elixir-lang/elixir/tags
# Compatibility between Erlang and Elixir versions:
# https://hexdocs.pm/elixir/1.14.4/compatibility-and-deprecations.html
ELIXIR_VERSION="${ELIXIRVERSION:-"latest"}"

# Build Erlang Docs
export KERL_BUILD_DOCS=yes

# Set Locale
LCL="${LOCALE:-"en_US.UTF-8"}"

# Set Username
USERNAME="${USER:-"root"}"

# Update packages
apt-get update && apt-get upgrade -y

# Create Elixir ASDF Script
export ELIXIR_ASDF_SCRIPT=/etc/profile.d/elixir-asdf.sh
touch $ELIXIR_ASDF_SCRIPT

# Set locale for elixir
apt-get install -y locales
locale-gen "${LCL}"
export LANG="${LCL}"
echo "export LANG=${LCL}" >> $ELIXIR_ASDF_SCRIPT

# Install ASDF
apt-get install -y curl git
mkdir -p /opt/asdf
# Where ASDF will be installed
export ASDF_DIR=/opt/asdf
echo "export ASDF_DIR=/opt/asdf" >> $ELIXIR_ASDF_SCRIPT
# Where ASDF will store plugins, versions, etc
export ASDF_DATA_DIR=/opt/asdf
echo "export ASDF_DATA_DIR=/opt/asdf" >> $ELIXIR_ASDF_SCRIPT
# Clone ASDF repo
git clone https://github.com/asdf-vm/asdf.git /opt/asdf --branch "v${ASDF_VERSION}"
# Add ASDF to PATH
export PATH=${PATH}:${ASDF_DIR}/shims:${ASDF_DIR}/bin
echo 'export PATH=$PATH:'"${ASDF_DIR}/shims:${ASDF_DIR}"'/bin' >> $ELIXIR_ASDF_SCRIPT
echo ". ${ASDF_DIR}/asdf.sh" >> $ELIXIR_ASDF_SCRIPT
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
asdf install erlang "${ERLANG_VERSION}"
asdf global erlang "${ERLANG_VERSION}"

# ASDF Elixir Prereqs
apt-get install -y unzip
# Install Elixir from ASDF and set global version
asdf install elixir "${ELIXIR_VERSION}"
asdf global elixir "${ELIXIR_VERSION}"
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

# Copy ASDF .tool-versions to user directory (if specified and not root) and make it accessible to everyone
if [ "${USERNAME}" != "root" ]; then
    mkdir -p "/home/${USERNAME}"
    cp "/root/.tool-versions" "/home/${USERNAME}/.tool-versions"
    chmod 777 "/home/${USERNAME}/.tool-versions"
    # Add write permissions (they already had read/execute) for everyone for ASDF-installed tools
    # Example use case: ElixirLS builds dialyzer in /opt/asdf/installs directory
    # Using 777 rather than changing ownership from root because I don't know if user's user exists yet
    chmod 777 -R /opt/asdf/installs
fi

echo 'Done!'
