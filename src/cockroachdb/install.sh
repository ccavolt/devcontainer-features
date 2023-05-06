#!/usr/bin/env bash

set -euxo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# https://github.com/cockroachdb/cockroach/tags
# CockroachDB version
export CRDB_VERSION=${VERSION:-"22.2.8"}

# Create download directory
export DOWNLOADDIR=$HOME/downloads
mkdir $DOWNLOADDIR

# Update packages
apt-get update && apt-get upgrade -y

# Install CockroachDB dependencies
apt-get install -y curl libc6 libncurses6 tzdata
# Download CockroachDB and unzip
cd $DOWNLOADDIR
curl "https://binaries.cockroachdb.com/cockroach-v${CRDB_VERSION}.linux-amd64.tgz" | tar -xzv
# Move CockroachDB Binary
mv cockroach-v${CRDB_VERSION}.linux-amd64/cockroach /usr/local/bin/
# Create directory and move lib
mkdir -p /usr/local/lib/cockroach
mv cockroach-v${CRDB_VERSION}.linux-amd64/lib/* /usr/local/lib/cockroach/

echo 'Done!'
