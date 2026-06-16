#!/bin/bash
set -e

: "${DOMAIN_NAME:?Need DOMAIN_NAME env var}"

mkdir -p /etc/ssl/private

if [ ! -f /etc/ssl/private/server.key ] || [ ! -f /etc/ssl/private/server.crt ]; then
  openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -subj "/CN=${DOMAIN_NAME}" \
    -keyout /etc/ssl/private/server.key \
    -out /etc/ssl/private/server.crt
  chmod 600 /etc/ssl/private/server.key
fi

# generate nginx conf
cat > /etc/nginx/conf.d/default.conf <<'NGINX_CONF'
server {
    listen 443 ssl http2;
    server_name __DOMAIN_NAME__;

    ssl_certificate /etc/ssl/private/server.crt;
    ssl_certificate_key /etc/ssl/private/server.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    root /var/www/html;
    index index.php index.html index.htm;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass wordpress:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    location ~ /\.ht {
        deny all;
    }
}
NGINX_CONF

sed -i "s|__DOMAIN_NAME__|${DOMAIN_NAME}|g" /etc/nginx/conf.d/default.conf

chown -R www-data:www-data /var/www/html || true

exec nginx -g "daemon off;"
