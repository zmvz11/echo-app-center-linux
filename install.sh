#!/usr/bin/env bash
set -euo pipefail
SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$HOME/.local/share/echo-app-center"
BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"

ensure_node() {
  if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    major="$(node -p "process.versions.node.split('.')[0]")"
    if [[ "$major" -ge 20 ]]; then
      echo "Node: $(node --version)"
      echo "npm:  $(npm --version)"
      return
    fi
  fi
  echo "Node.js 20+ is required. Install Node.js 24 LTS, then run ./install.sh again."
  exit 1
}

echo "============================================================"
echo " Echo App Center - Linux AppImage installer"
echo "============================================================"
ensure_node
cd "$SOURCE_ROOT"
npm config delete production --location=project >/dev/null 2>&1 || true
npm config set registry https://registry.npmjs.org/ --location=project >/dev/null

if [[ -x node_modules/.bin/electron-builder ]]; then
  echo "Dependencies already installed. Skipping npm install."
else
  echo "Installing dependencies from npm..."
  npm install --include=dev --no-audit --no-fund --registry https://registry.npmjs.org/
fi

echo "Running final checks..."
npm run final-check

echo "Building Linux AppImage..."
npm run package:linux
APPIMAGE="$(find release -maxdepth 1 -type f -name '*.AppImage' | sort | tail -n 1)"
if [[ -z "$APPIMAGE" ]]; then echo "No AppImage was created in release/."; exit 1; fi

mkdir -p "$APP_DIR" "$BIN_DIR" "$DESKTOP_DIR"
cp "$APPIMAGE" "$APP_DIR/EchoAppCenter.AppImage"
chmod +x "$APP_DIR/EchoAppCenter.AppImage"
cat > "$BIN_DIR/echo-app-center" <<EOF
#!/usr/bin/env bash
exec "$APP_DIR/EchoAppCenter.AppImage" "\$@"
EOF
chmod +x "$BIN_DIR/echo-app-center"
cat > "$DESKTOP_DIR/echo-app-center.desktop" <<EOF
[Desktop Entry]
Name=Echo App Center
Comment=Install and manage Echo apps
Exec=$APP_DIR/EchoAppCenter.AppImage
Terminal=false
Type=Application
Categories=Utility;
EOF

echo "============================================================"
echo " Echo App Center installed."
echo " Run it from your app launcher or type: echo-app-center"
echo "============================================================"
