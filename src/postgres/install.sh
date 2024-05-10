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
export REPO="https://github.com/postgres/postgres.git"
# Download directory
export DOWNLOADDIR=$HOME/downloads
mkdir -p "$DOWNLOADDIR"
# Postgres env script location
export POSTGRES_SCRIPT=/etc/profile.d/postgres.sh
touch $POSTGRES_SCRIPT
# Set Username
export PGUSER="${PGUSER:-"postgres"}"
echo 'export PGUSER='"$PGUSER" >> $POSTGRES_SCRIPT
adduser "$PGUSER" || echo "User already exists."
# Adds password accessible by psql
# Variable has to be called PGPASSWORD for psql to use it
export PGPASSWORD="${PGPASSWORD:-"postgres"}"
echo "export PGPASSWORD=${PGPASSWORD}" >> $POSTGRES_SCRIPT
# PG encoding is either specified or UTF8
export PGENCODING="${PGENCODING:-"UTF8"}"
echo "export PGENCODING=${PGENCODING}" >> $POSTGRES_SCRIPT
# Location of starting directory
WORKDIR=$(pwd)
export WORKDIR

# Copy command scripts to container
export CMDDIR=/devcontainer_features/postgres
mkdir -p "$CMDDIR"
cp "$WORKDIR/postAttachCommand.sh" "$CMDDIR"
cp "$WORKDIR/postCreateCommand.sh" "$CMDDIR"

# Postgres Base Directory
export PGDIR="/opt/postgres"
mkdir -p "$PGDIR"
# Postgres Bin Directory
export PGBIN="$PGDIR/bin"
# Postgres Data Directory
export PGDATA="$PGDIR/data"
echo 'export PGDATA='"$PGDATA" >> $POSTGRES_SCRIPT
mkdir -p "$PGDATA"
chown "$PGUSER" "$PGDATA"
# Add Postgres binaries to PATH
export PATH=$PATH:$PGBIN
# Ensure path isn't expanded, hence single quotes
# shellcheck disable=SC2016
echo 'export PATH=$PATH:'"$PGBIN" >> $POSTGRES_SCRIPT

# Update packages
apt-get update && apt-get upgrade -y

# Install git to determine latest version if necessary
apt-get install -y git

# https://www.postgresql.org/ftp/source/
# Postgres version to install
if [ -z "$VERSION" ] || [ "$VERSION" == "latest" ]
then
    POSTGRES_VERSION=$(git -c 'versionsort.suffix=-' \
        ls-remote --exit-code --refs --sort='version:refname' --tags "$REPO" '*_*' |
        grep -P "(REL_)\d\d(_)\d+" | # Removes alpha/beta/rc and non conforming tags
        tail --lines=1 | # Removes all but the latest tag
        cut --delimiter='/' --fields=3 | # Separates refs/tags/REL_15_3 to REL_15_3
        sed 's/[^0-9]*//' | # Removes everything before the first number
        sed 's/_/\./g') # Replaces _ with .
    export POSTGRES_VERSION
else
    export POSTGRES_VERSION=${VERSION}
fi

# Install wget to download postgres source code
apt-get install -y wget

# Postgres 16 fix for "ICU library not found"
apt-get install -y pkgconf libicu-dev

# Download postgres source code and unzip
cd "$DOWNLOADDIR"
wget "https://ftp.postgresql.org/pub/source/v${POSTGRES_VERSION}/postgresql-${POSTGRES_VERSION}.tar.gz"
tar -xf "postgresql-${POSTGRES_VERSION}.tar.gz"

# Install postgres dependencies and build
apt-get install -y build-essential libreadline-dev \
    zlib1g-dev flex bison libxml2-dev libxslt-dev \
    libssl-dev libxml2-utils xsltproc ccache
cd "postgresql-${POSTGRES_VERSION}"
./configure --prefix="$PGDIR" --with-openssl
make world
make install-world
su --login "$PGUSER" --command "${PGBIN}/initdb -D ${PGDATA} --data-checksums --username=${PGUSER} --encoding=${PGENCODING}"
su --login "$PGUSER" --command "${PGBIN}/pg_ctl -D ${PGDATA} -l logfile start"
su --login "$PGUSER" --command "${PGBIN}/createdb test"
su --login "$PGUSER" --command "${PGBIN}/psql test"

# Give db user a password to be able to connect to pgAdmin4
su --login "$PGUSER" --command "psql --echo-all --dbname=postgres --command \"alter user $PGUSER password '$PGPASSWORD'\"";

# Create database with name of user so connection that doesn't specify a database doesn't fail
# Skip if user is postgres because postgres database is created by default
if [ "$PGUSER" != "postgres" ]
then
  su --login "$PGUSER" --command "psql --echo-all --dbname=postgres --command \"create database $PGUSER\"";
fi

echo 'Done!'
