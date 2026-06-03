#!/usr/bin/env bash
set -euo pipefail

DEPLOY_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=config.env
source "$DEPLOY_DIR/config.env"

SECRETS_FILE="$DEPLOY_DIR/secrets.env"
CONF_FILE="$DEPLOY_DIR/nginx-peterlianpi.site.conf"
REMOTE_CONF="$NGINX_SITES/$NGINX_CONF"
TMP_CONF="/tmp/$NGINX_CONF"

if [[ ! -f "$CONF_FILE" ]]; then
  echo "Error: $CONF_FILE not found" >&2
  exit 1
fi

if [[ ! -f "$SECRETS_FILE" ]]; then
  echo "Error: $SECRETS_FILE not found. Copy secrets.env.example and set PORTFOLIO_CHAT_API_KEY." >&2
  exit 1
fi

# shellcheck source=secrets.env
source "$SECRETS_FILE"

if [[ -z "${PORTFOLIO_CHAT_API_KEY:-}" ]]; then
  echo "Error: PORTFOLIO_CHAT_API_KEY is empty in secrets.env" >&2
  exit 1
fi

echo "Preparing nginx config with portfolio chat key..."
sed "s/__PORTFOLIO_CHAT_API_KEY__/${PORTFOLIO_CHAT_API_KEY}/g" "$CONF_FILE" > "/tmp/nginx-${NGINX_CONF}.ready"
scp "/tmp/nginx-${NGINX_CONF}.ready" "$SSH_HOST:$TMP_CONF"

echo "Installing config and reloading nginx..."
ssh "$SSH_HOST" "sudo cp $TMP_CONF $REMOTE_CONF && sudo nginx -t && sudo systemctl reload nginx"

echo "Nginx config applied for $SITE_URL (static site + portfolio chat proxy)"
