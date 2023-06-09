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
# Adds password accessible by psql
# Variable has to be called PGPASSWORD for psql to use it
export PGPASSWORD="${PASSWORD:-"postgres"}"
# Postgres env script location
export POSTGRES_SCRIPT=/etc/profile.d/postgres.sh
# Location of starting directory
WORKDIR=$(pwd)
export WORKDIR


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

# Create download directory
mkdir "$DOWNLOADDIR"

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
./configure
make
make install
adduser postgres
mkdir -p /usr/local/pgsql/data
chown postgres /usr/local/pgsql/data
su --login postgres --command "/usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data"
su --login postgres --command "/usr/local/pgsql/bin/pg_ctl -D /usr/local/pgsql/data -l logfile start"
su --login postgres --command "/usr/local/pgsql/bin/createdb test"
su --login postgres --command "/usr/local/pgsql/bin/psql test"

# Create Postgres Script
touch $POSTGRES_SCRIPT
# Add Postgres binaries to PATH
export PATH=${PATH}:/usr/local/pgsql/bin
# Ensure path isn't expanded, hence single quotes
# shellcheck disable=SC2016
echo 'export PATH=$PATH:/usr/local/pgsql/bin' >> $POSTGRES_SCRIPT
# Default PGDATA directory from apt install
export PGDATA=/usr/local/pgsql/data
echo 'export PGDATA=/usr/local/pgsql/data' >> $POSTGRES_SCRIPT
# Enable data checksums (Postgres needs to be stopped first)
su --login postgres --command "pg_ctl -D $PGDATA stop"
pg_checksums --enable
# Start postgres
su --login postgres --command "pg_ctl -D $PGDATA start"
# Add Postgres password to script
echo "export PGPASSWORD=${PGPASSWORD}" >> $POSTGRES_SCRIPT
# Give postgres user a password to be able to connect to pgAdmin4
cp "$WORKDIR/init.sql" /home/postgres
su --login postgres --command "psql --echo-all -v pgpass=${PGPASSWORD} --file=init.sql"

echo 'Done!'
