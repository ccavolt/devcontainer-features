#!/bin/bash -i

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# https://github.com/asdf-vm/asdf/tags
if [ "${ASDFVERSION}" == "latest" ]
then
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

# To build Erlang documentation
export KERL_BUILD_DOCS=yes

# Update packages
apt-get update && apt-get upgrade -y

# Set locale for elixir
apt-get install -y locales
locale-gen "${LOCALE}"
export LANG="${LOCALE}"
echo "export LANG=${LOCALE}" >> "${HOME}/.profile"

# Setup default mix commands
if [ "${DEFAULTMIXCOMMANDS}" == "yes" ]
then
    cp .default-mix-commands "${HOME}"
fi

# Install ASDF
apt-get install -y curl git
git clone https://github.com/asdf-vm/asdf.git "${HOME}/.asdf" --branch "v${ASDF}"
# Add ASDF to PATH
export PATH="${HOME}/.asdf/shims:${HOME}/.asdf/bin:${PATH}"
echo "export PATH=${HOME}/.asdf/shims:${HOME}/.asdf/bin:${PATH}" >> "${HOME}/.profile"
# Ensure ASDF is up to date (if version isn't specified)
if [ "${ASDFVERSION}" == "latest" ]
then
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

echo 'Done!'
