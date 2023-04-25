#!/bin/bash -i

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

export POSTGRES="${VERSION:-"latest"}"
# Adds password accessible by psql
export PGPASSWORD="${POSTGRESPASSWORD:-"postgres"}"

# Update packages
apt-get update && apt-get upgrade -y

# Install Postgres Prereqs
apt-get install -y wget
# Create repo configuration
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
# Import the repository signing key
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
# Install Postgres and Postgres Contrib package which includes pg_stat_statements
if [ "${POSTGRES}" == "latest" ]
then
    apt-get install -y postgresql postgresql-contrib
else
    apt-get install -y "postgresql-${POSTGRES}" "postgresql-contrib-${POSTGRES}"
fi
# Add Postgres binaries to PATH
export PATH=${PATH}:/usr/lib/postgresql/${POSTGRES}/bin
echo "export PATH=${PATH}:/usr/lib/postgresql/${POSTGRES}/bin" >> "${HOME}/.profile"
# Default PGDATA directory from apt install
export PGDATA=/var/lib/postgresql/${POSTGRES}/main
echo "export PGDATA=/var/lib/postgresql/${POSTGRES}/main" >> "${HOME}/.profile"
# Enable data checksums
pg_checksums --enable
# Change password
service postgresql start && sudo -u postgres psql -c "alter user postgres PASSWORD 'postgres';"

echo 'Done!'
