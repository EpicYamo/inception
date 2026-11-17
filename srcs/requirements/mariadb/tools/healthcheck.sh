#!/bin/sh
set -eu

MYSQL_PWD=$(cat /run/secrets/db_password)
export MYSQL_PWD

exec mariadb --protocol=tcp --host=127.0.0.1 --user="$MYSQL_USER" "$MYSQL_DATABASE" --execute='SELECT 1' >/dev/null
