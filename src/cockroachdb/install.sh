#!/usr/bin/env bash

set -euxo pipefail

# Ensure script is running as root
if [ "$(id -u)" -ne 0 ]; then
  echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
  exit 1
fi

# Prevent installers from trying to prompt for information
export DEBIAN_FRONTEND=noninteractive
# Git Repo URL
export REPO="https://github.com/cockroachdb/cockroach.git"
# Download directory
export DOWNLOADDIR=$HOME/downloads

# Update packages
apt-get update && apt-get upgrade -y

# Install git to determine latest version if necessary
apt-get install -y git

# https://github.com/cockroachdb/cockroach/tags
# CockroachDB version to install
if [ -z "$VERSION" ] || [ "$VERSION" == "latest" ]; then
  CRDB_VERSION=$(git -c 'versionsort.suffix=-' \
    ls-remote --exit-code --refs --sort='version:refname' --tags "$REPO" '*.*.*' |
    grep -P "(/v)\d+(.)\d+(.)\d+$" | # Removes alpha/custombuild and non conforming tags
    tail --lines=1 |                 # Remove all but last line
    cut --delimiter='/' --fields=3 | # Remove refs and tags sections
    sed 's/[^0-9]*//')               # Remove v character so there's only numbers and periods
  export CRDB_VERSION
else
  export CRDB_VERSION=$VERSION
fi

# Create download directory
mkdir -p "$DOWNLOADDIR"

# Install CockroachDB dependencies
apt-get install -y libc6 libncurses6 tzdata
# Install curl to download CockroachDB
apt-get install -y curl
# Download CockroachDB and unzip
cd "$DOWNLOADDIR"
curl https://binaries.cockroachdb.com/cockroach-v"${CRDB_VERSION}".linux-amd64.tgz | tar -xzv
# Move CockroachDB Binary
mv cockroach-v"${CRDB_VERSION}".linux-amd64/cockroach /usr/local/bin/
# Create directory and move lib
mkdir -p /usr/local/lib/cockroach
mv cockroach-v"${CRDB_VERSION}".linux-amd64/lib/* /usr/local/lib/cockroach/

echo 'Done!'
