#!/bin/bash -i

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

export PGADMIN_SETUP_EMAIL='ccavolt@pm.me'
export PGADMIN_SETUP_PASSWORD='asdfasdf'

# Install pgAdmin 4
apt-get update && apt-get upgrade -y
apt-get install -y curl gpg lsb-release apt-utils
# Install the public key for the repository (if not done previously):
curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg
# Create the repository configuration file:
sh -c 'echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list && apt-get update'
# Install pgAdmin
# Have to specify installing server version (not just web) so install won't fail
# apt-get install pgadmin4-server=${PGADMIN4} pgadmin4-web=${PGADMIN4} -y
apt-get install -y pgadmin4-server pgadmin4-web
# Add local python binaries to path
export PATH=$PATH:${HOME}/.local/bin
# # Install venv
apt-get install -y python3-venv
# Add pgAdmin config
cp config_local.py /usr/pgadmin4/web
cat /usr/pgadmin4/web/config_local.py
echo "email address"
echo $PGADMIN_SETUP_EMAIL
echo "pgadmin password"
echo $PGADMIN_SETUP_PASSWORD
# Setup pgAdmin web server
/usr/pgadmin4/bin/setup-web.sh --yes
# Add local postgres server config to pgAdmin
cp pgadmin-server.json /usr/pgadmin4/web
sh -c ". /usr/pgadmin4/venv/bin/activate && exec python3 /usr/pgadmin4/web/setup.py --load-servers /usr/pgadmin4/web/pgadmin-server.json --replace --user $PGADMIN_SETUP_EMAIL"
echo 'Done!'
