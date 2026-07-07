#!/usr/bin/env bash
set -euo pipefail

APP_NAME="BlackPoint"
REPO="7757/BlackPoint"
ZIP_URL="${BLACKPOINT_ZIP_URL:-https://github.com/${REPO}/releases/latest/download/${APP_NAME}-macOS.zip}"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "Downloading ${APP_NAME}..."
if [[ "$ZIP_URL" == file://* ]]; then
  cp "${ZIP_URL#file://}" "$TMP_DIR/${APP_NAME}.zip"
else
  curl -fL "$ZIP_URL" -o "$TMP_DIR/${APP_NAME}.zip"
fi

echo "Installing to /Applications..."
pkill -x "$APP_NAME" >/dev/null 2>&1 || true
rm -rf "$TMP_DIR/${APP_NAME}.app"
ditto -x -k "$TMP_DIR/${APP_NAME}.zip" "$TMP_DIR"

if [[ ! -d "$TMP_DIR/${APP_NAME}.app" ]]; then
  echo "Could not find ${APP_NAME}.app in the downloaded archive." >&2
  exit 1
fi

rm -rf "/Applications/${APP_NAME}.app"
ditto "$TMP_DIR/${APP_NAME}.app" "/Applications/${APP_NAME}.app"
xattr -cr "/Applications/${APP_NAME}.app" >/dev/null 2>&1 || true
open "/Applications/${APP_NAME}.app"

echo "${APP_NAME} installed."
