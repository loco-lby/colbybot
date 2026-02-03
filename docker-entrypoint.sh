#!/bin/sh
set -e

# Fix permissions on /data volume if it exists and we're root
# Railway volumes are created as root, but we run as node user
if [ -d "/data" ] && [ "$(id -u)" = "0" ]; then
  chown -R node:node /data 2>/dev/null || true
  exec gosu node "$@"
else
  exec "$@"
fi
