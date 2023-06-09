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
# Adds password accessible by psql
# Variable has to be called PGPASSWORD for psql to use it
export PGPASSWORD="${PASSWORD:-"postgres"}"
echo "export PGPASSWORD=${PGPASSWORD}" >> $POSTGRES_SCRIPT
# Location of starting directory
WORKDIR=$(pwd)
export WORKDIR

# Postgres Base Directory
export PGDIR="/opt/postgres"
mkdir -p "$PGDIR"
# Postgres Bin Directory
export PGBIN="$PGDIR/bin"
# Postgres Data Directory
export PGDATA="$PGDIR/data"
echo 'export PGDATA='"$PGDATA" >> $POSTGRES_SCRIPT
# Add Postgres binaries to PATH
export PATH=$PATH:$PGBIN
# Ensure path isn't expanded, hence single quotes
# shellcheck disable=SC2016
echo 'export PATH=$PATH:'"$PGBIN" >> $POSTGRES_SCRIPT
# Set Username
export PGUSER="${USER:-"postgres"}"
echo 'export PGUSER='"$PGUSER" >> $POSTGRES_SCRIPT

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

# Download postgres source code and unzip
cd "$DOWNLOADDIR"
wget "https://ftp.postgresql.org/pub/source/v${POSTGRES_VERSION}/postgresql-${POSTGRES_VERSION}.tar.gz"
tar -xf "postgresql-${POSTGRES_VERSION}.tar.gz"

# Install postgres dependencies and build
apt-get install -y build-essential libreadline-dev \
    zlib1g-dev flex bison libxml2-dev libxslt-dev \
    libssl-dev libxml2-utils xsltproc ccache
cd "postgresql-${POSTGRES_VERSION}"
./configure --prefix="$PGDIR"
make world
make install-world
adduser "$PGUSER"
mkdir -p "$PGDATA"
chown "$PGUSER" "$PGDATA"
su --login "$PGUSER" --command "$PGBIN/initdb -D $PGDATA"
su --login "$PGUSER" --command "$PGBIN/pg_ctl -D $PGDATA -l logfile start"
su --login "$PGUSER" --command "$PGBIN/createdb test"
su --login "$PGUSER" --command "$PGBIN/psql test"

# Enable data checksums (Postgres needs to be stopped first)
su --login "$PGUSER" --command "pg_ctl -D $PGDATA stop"
pg_checksums --enable
su --login "$PGUSER" --command "pg_ctl -D $PGDATA start"

# Give db user a password to be able to connect to pgAdmin4
cp "$WORKDIR/init.sql" "/home/$PGUSER"
su --login "$PGUSER" --command "psql --echo-all -v pgpass=${PGPASSWORD} --file=init.sql"

echo 'Done!'
