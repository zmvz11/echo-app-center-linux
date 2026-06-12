#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export NPM_CONFIG_REGISTRY="https://registry.npmjs.org/"
npm run build
rm -rf release
npm exec electron-builder -- --linux AppImage tar.gz --x64
echo "Created Linux desktop release files in release/."
