#!/bin/bash
set -e

: "${MYSQL_DATABASE:?Need MYSQL_DATABASE env var}"
: "${MYSQL_USER:?Need MYSQL_USER env var}"
: "${MYSQL_PASSWORD:?Need MYSQL_PASSWORD env var}"
: "${MYSQL_HOST:=mariadb}"
: "${DOMAIN_NAME:?Need DOMAIN_NAME env var}"
: "${WP_ADMIN_USER:?Need WP_ADMIN_USER env var}"
: "${WP_ADMIN_PASSWORD:?Need WP_ADMIN_PASSWORD env var}"
: "${WP_ADMIN_EMAIL:=admin@${DOMAIN_NAME}}"

# Validate admin username
lc_admin="$(echo "$WP_ADMIN_USER" | tr '[:upper:]' '[:lower:]')"
if echo "$lc_admin" | grep -E 'admin|administrator' >/dev/null; then
  echo "Error: WP_ADMIN_USER cannot contain 'admin' or 'administrator'"
  exit 1
fi

WEBROOT="/var/www/html"
mkdir -p "$WEBROOT"
chown -R www-data:www-data "$WEBROOT"

if [ ! -f "$WEBROOT/wp-config.php" ]; then
  echo "Downloading and installing WordPress..."
  wget -qO /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
  tar -xzf /tmp/wordpress.tar.gz -C /tmp
  rsync -a /tmp/wordpress/ "$WEBROOT/"
  chown -R www-data:www-data "$WEBROOT"

  # install WP-CLI
  wget -qO /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod +x /usr/local/bin/wp

  echo "Waiting for database at ${MYSQL_HOST}..."
  until mysql -h"${MYSQL_HOST}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SELECT 1;" >/dev/null 2>&1; do
    sleep 1
  done

  cd "$WEBROOT"

  echo "Creating wp-config.php..."
  wp core config --dbname="${MYSQL_DATABASE}" --dbuser="${MYSQL_USER}" --dbpass="${MYSQL_PASSWORD}" --dbhost="${MYSQL_HOST}" --skip-check --allow-root

  echo "Installing WordPress core..."
  wp core install --url="https://${DOMAIN_NAME}" --title="${DOMAIN_NAME}" --admin_user="${WP_ADMIN_USER}" --admin_password="${WP_ADMIN_PASSWORD}" --admin_email="${WP_ADMIN_EMAIL}" --skip-email --allow-root

  echo "Creating secondary user..."
  wp user create contributor contributor@${DOMAIN_NAME} --user_pass="${MYSQL_PASSWORD}" --role=editor --allow-root || true

  chown -R www-data:www-data "$WEBROOT"
fi

# Ensure php-fpm listens on TCP 9000
if [ -d /etc/php ]; then
  for pool in /etc/php/*/fpm/pool.d/www.conf; do
    if [ -f "$pool" ]; then
      sed -i 's|^listen = .*|listen = 0.0.0.0:9000|' "$pool" || true
    fi
  done
fi

echo "Starting php-fpm in foreground..."
if command -v php-fpm >/dev/null 2>&1; then
  exec php-fpm -F
elif command -v php7.4-fpm >/dev/null 2>&1; then
  exec php7.4-fpm -F
elif command -v php-fpm7.4 >/dev/null 2>&1; then
  exec php-fpm7.4 -F
else
  echo "php-fpm not found"
  exit 1
fi
