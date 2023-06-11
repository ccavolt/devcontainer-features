#!/usr/bin/env bash

set -eouvx pipefail

# Idempotently start postgres
# Use sudo if not running as root to prevent pw prompt
if [ "$(id -u)" -ne 0 ]
then
  sudo su --login "$PGUSER" --command "pg_ctl -D $PGDATA restart"
else
  su --login "$PGUSER" --command "pg_ctl -D $PGDATA restart"
fi
