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

# Extract AppImage, embed .love, repack
APPIMAGE_WORK="${BUILD_DIR}/_appimage_work"
rm -rf "$APPIMAGE_WORK"
mkdir -p "$APPIMAGE_WORK"

# Find squashfs offset (use last 'hsqs' match — first may be inside ELF binary)
OFFSET=$(grep -aob 'hsqs' "$APPIMAGE_SRC" | tail -1 | cut -d: -f1)
dd if="$APPIMAGE_SRC" bs=1 count="$OFFSET" of="${APPIMAGE_WORK}/runtime" 2>/dev/null
dd if="$APPIMAGE_SRC" bs=1 skip="$OFFSET" of="${APPIMAGE_WORK}/squashfs.img" 2>/dev/null
unsquashfs -d "${APPIMAGE_WORK}/squashfs-root" "${APPIMAGE_WORK}/squashfs.img"

# Place the .love file inside the AppImage
cp "$LOVE_FILE" "${APPIMAGE_WORK}/squashfs-root/${GAME_NAME}.love"

# Enable the built-in FUSE_PATH in AppRun
sed -i "s|^#FUSE_PATH=\"\$APPDIR/my_game.love\"|FUSE_PATH=\"\$APPDIR/${GAME_NAME}.love\"|" \
    "${APPIMAGE_WORK}/squashfs-root/AppRun"

# Repack: runtime header + new squashfs
mksquashfs "${APPIMAGE_WORK}/squashfs-root" "${APPIMAGE_WORK}/new.squashfs" \
    -root-owned -noappend -comp gzip -no-progress
cat "${APPIMAGE_WORK}/runtime" "${APPIMAGE_WORK}/new.squashfs" > "$APPIMAGE_OUT"
chmod +x "$APPIMAGE_OUT"
rm -rf "$APPIMAGE_WORK"

# --- Done ---
echo ""
echo "=== Build complete ==="
echo "  ${BUILD_DIR}/${GAME_NAME}.love"
echo "  ${WIN_DIR}/${GAME_NAME}.exe"
echo "  ${MAC_DIR}/"
echo "  ${APPIMAGE_OUT}"
