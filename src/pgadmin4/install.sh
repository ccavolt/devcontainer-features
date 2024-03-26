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
export REPO="https://github.com/pgadmin-org/pgadmin4.git"
# pgAdmin Setup Email
export PGADMIN_SETUP_EMAIL="${EMAIL:-"john@smith.dev"}"
# pgAdmin Setup Password
export PGADMIN_SETUP_PASSWORD="${PASSWORD:-"asdfasdf"}"

# Update packages
apt-get update && apt-get upgrade -y

# Install git to determine latest version if necessary
apt-get install -y git

# https://github.com/pgadmin-org/pgadmin4/tags
# pgAdmin version to install
if [ -z "$VERSION" ] || [ "$VERSION" == "latest" ]
then
    PGADMIN_VERSION=$(git -c 'versionsort.suffix=-' \
        ls-remote --exit-code --refs --sort='version:refname' --tags "$REPO" '*_*' \
        | tail --lines=1 \
        | cut --delimiter='/' --fields=3 \
        | sed 's/[^0-9]*//' \
        | sed 's/_/\./g')
    export PGADMIN_VERSION
else
    export PGADMIN_VERSION=${VERSION}
fi

# Install prereqs
apt-get install -y curl gpg lsb-release apt-utils
# Install the public key for the repository (if not done previously):
curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg
# Create the repository configuration file:
sh -c 'echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list && apt-get update'
# Install pgAdmin
# Have to specify installing server version (not just web) so install won't fail
apt-get install -y pgadmin4-server="${PGADMIN_VERSION}" pgadmin4-web="${PGADMIN_VERSION}"

# Install venv
apt-get install -y python3-venv
# Add pgAdmin config
cp config_local.py /usr/pgadmin4/web
# Setup pgAdmin web server
/usr/pgadmin4/bin/setup-web.sh --yes
# Add local postgres server config to pgAdmin
cp pgadmin-server.json /usr/pgadmin4/web
# Activate venv and run setup.py
sh -c ". /usr/pgadmin4/venv/bin/activate && exec python3 /usr/pgadmin4/web/setup.py load-servers /usr/pgadmin4/web/pgadmin-server.json --replace --user $PGADMIN_SETUP_EMAIL"

echo 'Done!'
