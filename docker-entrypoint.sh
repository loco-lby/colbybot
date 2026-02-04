#!/bin/sh
set -e

# Determine state directory (Railway uses /data, fallback to home)
STATE_DIR="${OPENCLAW_STATE_DIR:-/data/.openclaw}"
CONFIG_FILE="${STATE_DIR}/openclaw.json"

# Create state directory if needed
mkdir -p "$STATE_DIR" 2>/dev/null || true

# Write initial config if it doesn't exist
# This enables token auth to bypass device pairing (required for Railway)
if [ ! -f "$CONFIG_FILE" ]; then
  cat > "$CONFIG_FILE" << 'CONFIGEOF'
{
  "gateway": {
    "controlUi": {
      "allowInsecureAuth": true
    }
  }
}
CONFIGEOF
fi

# Fix permissions on /data volume if it exists and we're root
# Railway volumes are created as root, but we run as node user
if [ -d "/data" ] && [ "$(id -u)" = "0" ]; then
  chown -R node:node /data 2>/dev/null || true
  exec gosu node "$@"
else
  exec "$@"
fi
