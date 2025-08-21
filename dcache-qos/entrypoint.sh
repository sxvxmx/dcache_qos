#!/bin/bash
sleep 20
DATA_DIR="data"

service postgresql start

if [ "$1" = 'postgres' ] && [ -z "$(ls -A "$DATA_DIR")" ]; then
    echo "Initializing PostgreSQL database..."
    /usr/pgsql-14/bin/postgresql-14-setup initdb
fi

dcache database update

dcache start

tail -f /var/log/dcache/qosDomain.log