#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="$REPO_ROOT/VideoSpeed/Config"

mkdir -p "$CONFIG_DIR"
echo "API_KEY = ${CI_ENV_API_KEY}" > "$CONFIG_DIR/Secrets.xcconfig"

cd "$REPO_ROOT"
pod install
