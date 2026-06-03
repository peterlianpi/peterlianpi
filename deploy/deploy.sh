#!/usr/bin/env bash
# Deploy portfolio (build + upload dist/)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEPLOY_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=config.env
source "$DEPLOY_DIR/config.env"

"$ROOT/scripts/build.sh"

DIST="$ROOT/dist"
INDEX_FILE="$DIST/index.html"
ASSETS_DIR="$DIST/assets"
DATA_DIR="$DIST/data"

if [[ ! -f "$INDEX_FILE" ]]; then
  echo "Error: dist/index.html not found" >&2
  exit 1
fi

echo "Backing up current live site..."
ssh "$SSH_HOST" "sudo cp $REMOTE_DIR/$REMOTE_INDEX $REMOTE_DIR/$REMOTE_INDEX.bak"

echo "Uploading $REMOTE_INDEX..."
scp "$INDEX_FILE" "$SSH_HOST:/tmp/$REMOTE_INDEX"
ssh "$SSH_HOST" "sudo cp /tmp/$REMOTE_INDEX $REMOTE_DIR/$REMOTE_INDEX && rm /tmp/$REMOTE_INDEX"

if [[ -d "$ASSETS_DIR" ]]; then
  echo "Uploading assets/..."
  ssh "$SSH_HOST" "mkdir -p /tmp/portfolio-assets && rm -rf /tmp/portfolio-assets/*"
  scp -r "$ASSETS_DIR/"* "$SSH_HOST:/tmp/portfolio-assets/"
  ssh "$SSH_HOST" "sudo mkdir -p $REMOTE_DIR/assets && sudo rm -rf $REMOTE_DIR/assets/* && sudo cp -r /tmp/portfolio-assets/* $REMOTE_DIR/assets/ && rm -rf /tmp/portfolio-assets"
fi

if [[ -d "$DATA_DIR" ]]; then
  echo "Uploading data/..."
  ssh "$SSH_HOST" "mkdir -p /tmp/portfolio-data"
  scp -r "$DATA_DIR/"* "$SSH_HOST:/tmp/portfolio-data/"
  ssh "$SSH_HOST" "sudo mkdir -p $REMOTE_DIR/data && sudo cp -r /tmp/portfolio-data/* $REMOTE_DIR/data/ && rm -rf /tmp/portfolio-data"
fi

echo "Setting permissions..."
ssh "$SSH_HOST" "sudo chown -R root:root $REMOTE_DIR && sudo find $REMOTE_DIR -type f -exec chmod 644 {} \;"

echo "Deployed to $SITE_URL"
