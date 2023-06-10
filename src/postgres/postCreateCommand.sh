#!/usr/bin/env bash

set -eouvx pipefail

sudo su --login "$PGUSER" --command "pg_ctl -D $PGDATA restart"
