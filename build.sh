#!/usr/bin/env bash
set -euo pipefail

LOVE_VERSION="${LOVE_VERSION:-11.5}"
GAME_NAME="${GAME_NAME:-game}"
LOVE_DIR="/opt/love"
BUILD_DIR="/game/build"
SRC_DIR="/game/src"

echo "=== Building ${GAME_NAME} with Love2D ${LOVE_VERSION} ==="

# Clean previous build
rm -rf "${BUILD_DIR:?}"/*

# --- 1. Create .love file ---
echo "--- Creating ${GAME_NAME}.love ---"
(cd "$SRC_DIR" && zip -9 -r "${BUILD_DIR}/${GAME_NAME}.love" . -x ".*")

LOVE_FILE="${BUILD_DIR}/${GAME_NAME}.love"

# --- 2. Windows (win64) ---
echo "--- Packaging Windows build ---"
WIN_DIR="${BUILD_DIR}/windows/${GAME_NAME}-win64"
mkdir -p "$WIN_DIR"

cat "${LOVE_DIR}/win64/love.exe" "$LOVE_FILE" > "${WIN_DIR}/${GAME_NAME}.exe"

# Copy all DLLs and license
cp "${LOVE_DIR}"/win64/*.dll "$WIN_DIR"/
cp "${LOVE_DIR}/win64/license.txt" "$WIN_DIR/" 2>/dev/null || true

# --- 3. macOS ---
echo "--- Packaging macOS build ---"
MAC_DIR="${BUILD_DIR}/macos/${GAME_NAME}-macos.app"
mkdir -p "${BUILD_DIR}/macos"
cp -r "${LOVE_DIR}/macos/love.app" "$MAC_DIR"

# Insert game.love into the app bundle
cp "$LOVE_FILE" "${MAC_DIR}/Contents/Resources/${GAME_NAME}.love"

# Patch Info.plist — replace bundle identifier and name
PLIST="${MAC_DIR}/Contents/Info.plist"
if [ -f "$PLIST" ]; then
    sed -i "s/org\.love2d\.love/com.game.${GAME_NAME}/g" "$PLIST"
    sed -i "s/<string>LÖVE<\/string>/<string>${GAME_NAME}<\/string>/g" "$PLIST"
fi

# --- 4. Linux (AppImage) ---
echo "--- Packaging Linux build ---"
LINUX_DIR="${BUILD_DIR}/linux"
mkdir -p "$LINUX_DIR"

APPIMAGE_SRC="${LOVE_DIR}/linux/love-${LOVE_VERSION}-x86_64.AppImage"
APPIMAGE_OUT="${LINUX_DIR}/${GAME_NAME}-linux-x86_64.AppImage"

cat "$APPIMAGE_SRC" "$LOVE_FILE" > "$APPIMAGE_OUT"
chmod +x "$APPIMAGE_OUT"

# --- Done ---
echo ""
echo "=== Build complete ==="
echo "  ${BUILD_DIR}/${GAME_NAME}.love"
echo "  ${WIN_DIR}/${GAME_NAME}.exe"
echo "  ${MAC_DIR}/"
echo "  ${APPIMAGE_OUT}"
