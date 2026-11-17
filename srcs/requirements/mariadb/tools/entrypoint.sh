#!/bin/sh
set -eu

DATA_DIR=/var/lib/mysql
RUN_DIR=/run/mysqld
SOCKET="$RUN_DIR/mysqld.sock"
PID_FILE="$RUN_DIR/mysqld.pid"
INITIALIZED_MARKER="$DATA_DIR/.inception_initialized"
TEMP_PID=

fail() {
	printf '%s\n' "$1" >&2
	exit 1
}

cleanup() {
	if [ -n "$TEMP_PID" ] && kill -0 "$TEMP_PID" 2>/dev/null; then
		kill "$TEMP_PID" 2>/dev/null || true
		wait "$TEMP_PID" 2>/dev/null || true
	fi
}

if [ ! -f "$INITIALIZED_MARKER" ]; then
	: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
	: "${MYSQL_USER:?MYSQL_USER is required}"
	[ -s /run/secrets/db_root_password ] || fail "The database root password secret is missing or empty."
	[ -s /run/secrets/db_password ] || fail "The database user password secret is missing or empty."

	case "$MYSQL_DATABASE" in
		*[!A-Za-z0-9_]*|'') fail "MYSQL_DATABASE may contain only letters, numbers, and underscores." ;;
	esac
	case "$MYSQL_USER" in
		*[!A-Za-z0-9_]*|'') fail "MYSQL_USER may contain only letters, numbers, and underscores." ;;
	esac

	ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
	DB_PASSWORD=$(cat /run/secrets/db_password)
	case "$ROOT_PASSWORD" in
		*[!A-Za-z0-9]*|'') fail "The database root password must be non-empty and alphanumeric." ;;
	esac
	case "$DB_PASSWORD" in
		*[!A-Za-z0-9]*|'') fail "The database user password must be non-empty and alphanumeric." ;;
	esac

	install -d -o mysql -g mysql "$RUN_DIR" "$DATA_DIR"
	if [ ! -d "$DATA_DIR/mysql" ]; then
		mariadb-install-db --user=mysql --datadir="$DATA_DIR" --auth-root-authentication-method=normal --skip-test-db
	fi

	mariadbd --user=mysql --datadir="$DATA_DIR" --socket="$SOCKET" --pid-file="$PID_FILE" --skip-networking &
	TEMP_PID=$!
	trap cleanup EXIT

	mariadb-admin --socket="$SOCKET" --user=root --wait=30 ping

mariadb --socket="$SOCKET" --user=root <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
ALTER USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
SQL

	mariadb-admin --socket="$SOCKET" --user=root --password="$ROOT_PASSWORD" shutdown
	wait "$TEMP_PID"
	TEMP_PID=
	trap - EXIT
	touch "$INITIALIZED_MARKER"
	chown mysql:mysql "$INITIALIZED_MARKER"
fi

exec mariadbd --user=mysql --console --bind-address=0.0.0.0 "$@"
