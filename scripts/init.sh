#!/bin/sh
# Prepares everything the web server needs, idempotently.
set -e

apk add --no-cache openssl apache2-utils >/dev/null 2>&1

CERT=/certs/server.crt
KEY=/certs/server.key

if [ ! -f "$CERT" ] || [ ! -f "$KEY" ]; then
  echo "[init] generating self-signed certificate for 127.0.0.1"
  openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
    -keyout "$KEY" -out "$CERT" \
    -subj "/C=SG/ST=Singapore/L=Singapore/O=SIT/OU=SSD/CN=127.0.0.1" \
    -addext "subjectAltName=IP:127.0.0.1,DNS:localhost"
  chmod 644 "$CERT" "$KEY"
else
  echo "[init] certificate already present, skipping"
fi

if [ ! -f /auth/.htpasswd ]; then
  echo "[init] creating basic-auth user 'admin'"
  htpasswd -cbB /auth/.htpasswd admin '2400639@sit.singaporetech.edu.sg'
  chmod 644 /auth/.htpasswd
else
  echo "[init] .htpasswd already present, skipping"
fi

echo "[init] done"
