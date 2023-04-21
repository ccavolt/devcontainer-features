#!/bin/bash -i

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# https://github.com/asdf-vm/asdf/tags
export ASDF=$ASDFVERSION
# https://github.com/erlang/otp/tags           
export ERLANG=$ERLANGVERSION
# https://github.com/elixir-lang/elixir/tags
# Compatibility between Erlang and Elixir versions:
# https://hexdocs.pm/elixir/1.14.4/compatibility-and-deprecations.html
export ELIXIR=$ELIXIRVERSION

# Update packages
apt-get update && apt-get upgrade -y

# Set locale for elixir
apt-get install -y locales
locale-gen en_US.UTF-8
export LANG=en_US.UTF-8
echo 'export LANG=en_US.UTF-8' >> ${HOME}/.profile

# Install ASDF
export ASDFPATH=${HOME}/.asdf/bin/asdf
apt-get install curl git -y
git clone https://github.com/asdf-vm/asdf.git ${HOME}/.asdf --branch v${ASDF}
# Add ASDF to PATH
export PATH="${HOME}/.asdf/shims:${HOME}/.asdf/bin:${PATH}"
echo 'export PATH="${HOME}/.asdf/shims:${HOME}/.asdf/bin:${PATH}"' >> ${HOME}/.profile
# Ensure ASDF is up to date
asdf update

# Install Erlang & Elixir ASDF plugins
asdf plugin-add erlang
asdf plugin-add elixir
# Ensure ASDF plugins are up to date
asdf plugin-update --all
# To build Erlang documentation
export KERL_BUILD_DOCS=yes
# ASDF Erlang Prereqs
apt-get -y install build-essential autoconf m4 libncurses5-dev \
   libwxgtk3.0-gtk3-dev libwxgtk-webview3.0-gtk3-dev libgl1-mesa-dev \
   libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop \
   libxml2-utils libncurses-dev openjdk-11-jdk
# Install Erlang from ASDF and set global version
asdf install erlang $ERLANG
asdf global erlang $ERLANG
# ASDF Elixir Prereqs
apt-get install unzip -y
# Install Elixir from ASDF and set global version
asdf install elixir $ELIXIR
asdf global elixir $ELIXIR
# Install filesystem watcher for live reloading to work
apt-get install inotify-tools -y
# Install Hex Package Manager
# export MIXPATH=${HOME}/.asdf/installs/elixir/${ELIXIR}/bin/mix
# echo 'export MIXPATH=${HOME}/.asdf/installs/elixir/${ELIXIR}/bin/mix' >> ${HOME}/.profile
mix local.hex --force
# Install rebar3 to build Erlang dependencies
mix local.rebar --force
# Install Phoenix Framework Application Generator
mix archive.install hex phx_new --force

echo 'Done!'
