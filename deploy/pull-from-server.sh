#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEPLOY_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=config.env
source "$DEPLOY_DIR/config.env"

echo "Downloading $REMOTE_INDEX..."
scp "$SSH_HOST:$REMOTE_DIR/$REMOTE_INDEX" "$ROOT/$REMOTE_INDEX"

echo "Downloading backup..."
scp "$SSH_HOST:$REMOTE_DIR/$REMOTE_INDEX.bak" "$ROOT/$REMOTE_INDEX.bak"

echo "Done. Files saved to $ROOT"
