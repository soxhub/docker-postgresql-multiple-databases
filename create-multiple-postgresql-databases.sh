#!/bin/bash

set -e
set -u

function create_user_and_database() {
	local database=$1
	echo "  Creating user and database '$database'"
	psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
	    CREATE USER $database;
	    CREATE DATABASE $database;
	    GRANT ALL PRIVILEGES ON DATABASE $database TO $database;
EOSQL
}

function improve_postgres_performance() {
	echo "Configuring psql with improved performance..."

	sed -ri "s/^#*(fsync\s*=\s*)\S+/\1 off/" "$PGDATA"/postgresql.conf
	sed -ri "s/^#*(full_page_writes\s*=\s*)\S+/\1 off/" "$PGDATA"/postgresql.conf
	sed -ri "s/^#*(random_page_cost\s*=\s*)\S+/\1 2.0/" "$PGDATA"/postgresql.conf
	sed -ri "s/^#*(checkpoint_segments\s*=\s*)\S+/\1 64/" "$PGDATA"/postgresql.conf
	sed -ri "s/^#*(checkpoint_completion_target\s*=\s*)\S+/\1 0.9/" "$PGDATA"/postgresql.conf
  sed -ri "s/^#*(work_mem\s*=\s*)\S+/\1 64MB/" "$PGDATA"/postgresql.conf
	sed -ri "s/^#*(shared_buffers\s*=\s*)\S+/\1 2056MB/" "$PGDATA"/postgresql.conf

	grep fsync "$PGDATA"/postgresql.conf
}

if [ -n "$POSTGRES_MULTIPLE_DATABASES" ]; then
	improve_postgres_performance
	echo "Multiple database creation requested: $POSTGRES_MULTIPLE_DATABASES"
	for db in $(echo $POSTGRES_MULTIPLE_DATABASES | tr ',' ' '); do
		create_user_and_database $db
	done
	echo "Multiple databases created"
fi
