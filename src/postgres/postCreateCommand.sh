#!/usr/bin/env bash

set -eouvx pipefail

# Idempotently start postgres
su --login "$PGUSER" --command "pg_ctl -D $PGDATA restart"
