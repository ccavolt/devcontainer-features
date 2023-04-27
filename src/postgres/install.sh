#!/bin/bash -i

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# PostgreSQL version
export POSTGRES=${VERSION:-"15"}
# Adds password accessible by psql
export PGPASSWORD="${POSTGRESPASSWORD:-"postgres"}"

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
apt-get install -y "postgresql-${POSTGRES}" "postgresql-contrib-${POSTGRES}"
# Create PGPROFILE
export DCFEATURES=/etc/profile.d/dcfeatures
touch $DCFEATURES
# Add Postgres binaries to PATH
export PATH=${PATH}:/usr/lib/postgresql/${POSTGRES}/bin
echo "export PATH=\"${PATH}:/usr/lib/postgresql/${POSTGRES}/bin\"" >> $DCFEATURES
# Default PGDATA directory from apt install
export PGDATA=/var/lib/postgresql/${POSTGRES}/main
echo "export PGDATA=/var/lib/postgresql/${POSTGRES}/main" >> $DCFEATURES
# Enable data checksums
pg_checksums --enable
# Start postgres service
service postgresql start
# Give postgres user a password to be able to connect to pgAdmin4
su postgres --command "psql --echo-all -v pgpass=${PGPASSWORD} --file=init.sql"

echo 'Done!'
