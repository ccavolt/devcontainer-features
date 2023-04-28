#!/bin/bash -i

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# PostgreSQL version
export POSTGRES_VERSION=${VERSION:-"15"}
# Adds password accessible by psql
export POSTGRES_PASSWORD="${PASSWORD:-"postgres"}"

# Create Postgres Script
export POSTGRES_SCRIPT=/etc/profile.d/postgres.sh
touch $POSTGRES_SCRIPT

# Add Postgres password to script
echo "export POSTGRES_PASSWORD=${POSTGRES_PASSWORD}" >> $POSTGRES_SCRIPT

# Update packages
apt-get update && apt-get upgrade -y

# Install Postgres Prereqs
apt-get install -y wget gnupg lsb-release
# Create repo configuration
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
# Import the repository signing key
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
# Update apt because of newly imported repo
apt-get update
# Install Postgres and Postgres Contrib package which includes pg_stat_statements
apt-get install -y "postgresql-${POSTGRES_VERSION}" "postgresql-contrib-${POSTGRES_VERSION}"
# Add Postgres binaries to PATH
export PATH=${PATH}:/usr/lib/postgresql/${POSTGRES_VERSION}/bin
echo 'export PATH=$PATH:/usr/lib/postgresql/'"${POSTGRES_VERSION}"'/bin' >> $POSTGRES_SCRIPT
# Default PGDATA directory from apt install
export PGDATA=/var/lib/postgresql/${POSTGRES_VERSION}/main
echo 'export PGDATA=/var/lib/postgresql/'"${POSTGRES_VERSION}"'/main' >> $POSTGRES_SCRIPT
# Enable data checksums
pg_checksums --enable
# Start postgres service
service postgresql start
# Give postgres user a password to be able to connect to pgAdmin4
su postgres --command "psql --echo-all -v pgpass=${POSTGRES_PASSWORD} --file=init.sql"

echo 'Done!'
