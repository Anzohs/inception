#!/bin/bash
set -e

: "${MYSQL_ROOT_PASSWORD:?Need MYSQL_ROOT_PASSWORD env var}"
: "${MYSQL_DATABASE:=wordpress}"
: "${MYSQL_USER:=wp_user}"
: "${MYSQL_PASSWORD:?Need MYSQL_PASSWORD env var}"

DATADIR="/var/lib/mysql"
SOCKET="/var/run/mysqld/mysqld.sock"

# Ensure directories and ownership
mkdir -p "$DATADIR" /var/run/mysqld
chown -R mysql:mysql "$DATADIR" /var/run/mysqld

if [ ! -d "$DATADIR/mysql" ]; then
  echo "Initializing MariaDB data directory..."
  if command -v mysql_install_db >/dev/null 2>&1; then
    mysql_install_db --user=mysql --datadir="$DATADIR" --rpm || true
  else
    mysqld --initialize-insecure --user=mysql --datadir="$DATADIR"
  fi

  echo "Starting temporary MariaDB server..."
  mysqld --user=mysql --datadir="$DATADIR" --skip-networking --socket="$SOCKET" &
  pid="$!"

  # wait for server
  for i in $(seq 30); do
    if mysqladmin ping --socket="$SOCKET" &>/dev/null; then
      break
    fi
    sleep 1
  done

  echo "Configuring database and users..."
  mysql --socket="$SOCKET" -uroot <<-EOSQL
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
    CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
    GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
    FLUSH PRIVILEGES;
EOSQL

  echo "Stopping temporary server..."
  mysqladmin --socket="$SOCKET" -uroot -p"${MYSQL_ROOT_PASSWORD}" shutdown || kill "$pid"
fi

echo "Starting MariaDB server in foreground..."
exec mysqld --user=mysql --datadir="$DATADIR"
