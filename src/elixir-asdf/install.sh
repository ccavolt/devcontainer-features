#!/bin/bash -i

set -e

ASDF=$ASDFVERSION
                  
ERLANG=$ERLANGVERSION

ELIXIR=$ELIXIRVERSION

# Update packages
sudo apt-get update && sudo apt-get upgrade -y

# Install ASDF
ASDFPATH=$HOME/.asdf/bin/asdf
sudo apt-get install curl git -y
git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf --branch v$ASDF
# Ensure ASDF is up to date
$ASDFPATH update
# Add ASDF to PATH
PATH=$HOME/.asdf/shims:$HOME/.asdf/bin:$PATH

# Install Erlang & Elixir ASDF plugins
$ASDFPATH plugin-add erlang
$ASDFPATH plugin-add elixir
# Ensure ASDF plugins are up to date
$ASDFPATH plugin-update --all
# To build Erlang documentation
KERL_BUILD_DOCS=yes
# ASDF Erlang Prereqs
sudo apt-get -y install build-essential autoconf m4 libncurses5-dev \
   libwxgtk3.0-gtk3-dev libwxgtk-webview3.0-gtk3-dev libgl1-mesa-dev \
   libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop \
   libxml2-utils libncurses-dev openjdk-11-jdk
# Install Erlang from ASDF and set global version
$ASDFPATH install erlang $ERLANG
$ASDFPATH global erlang $ERLANG
# ASDF Elixir Prereqs
sudo apt-get install unzip -y
# Install Elixir from ASDF and set global version
$ASDFPATH install elixir $ELIXIR
$ASDFPATH global elixir $ELIXIR
# Install filesystem watcher for live reloading to work
sudo apt-get install inotify-tools -y
# Install Hex Package Manager
MIXPATH=$HOME/.asdf/installs/elixir/$ELIXIR/bin/mix
$MIXPATH local.hex --force
# Install rebar3 to build Erlang dependencies
$MIXPATH local.rebar --force
# Install Phoenix Framework Application Generator
$MIXPATH archive.install hex phx_new --force

echo 'Done!'
