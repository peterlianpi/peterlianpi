#!/usr/bin/env bash
# Build static site -> dist/
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if command -v pwsh >/dev/null 2>&1; then
  pwsh -File "$ROOT/scripts/build.ps1"
elif command -v powershell >/dev/null 2>&1; then
  powershell -ExecutionPolicy Bypass -File "$ROOT/scripts/build.ps1"
else
  echo "PowerShell required to run build.ps1" >&2
  exit 1
fi
