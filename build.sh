#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="BatchPrint"
BUNDLE_NAME="${APP_NAME}.app"
BUILD_DIR="${ROOT_DIR}/.build/manual"
APP_DIR="${ROOT_DIR}/${BUNDLE_NAME}"
MIN_MACOS="13.0"

cd "${ROOT_DIR}"

mkdir -p "${BUILD_DIR}"

echo "▸ Compiling universal binary…"
for ARCH in arm64 x86_64; do
    echo "  · ${ARCH}"
    swiftc \
        -O \
        -whole-module-optimization \
        -parse-as-library \
        -target "${ARCH}-apple-macosx${MIN_MACOS}" \
        Sources/BatchPrint/*.swift \
        -o "${BUILD_DIR}/${APP_NAME}-${ARCH}"
done

lipo -create \
    "${BUILD_DIR}/${APP_NAME}-arm64" \
    "${BUILD_DIR}/${APP_NAME}-x86_64" \
    -output "${BUILD_DIR}/${APP_NAME}"

echo "▸ Assembling app bundle…"
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS" "${APP_DIR}/Contents/Resources"

cp "${BUILD_DIR}/${APP_NAME}" "${APP_DIR}/Contents/MacOS/${APP_NAME}"
cp Info.plist "${APP_DIR}/Contents/Info.plist"
cp Resources/AppIcon.icns "${APP_DIR}/Contents/Resources/AppIcon.icns"
for LPROJ in Resources/*.lproj(N); do
    cp -R "${LPROJ}" "${APP_DIR}/Contents/Resources/"
done
printf 'APPL????' > "${APP_DIR}/Contents/PkgInfo"
chmod +x "${APP_DIR}/Contents/MacOS/${APP_NAME}"

plutil -lint "${APP_DIR}/Contents/Info.plist" >/dev/null
codesign --force --sign - "${APP_DIR}" >/dev/null 2>&1 || true
xattr -cr "${APP_DIR}" >/dev/null 2>&1 || true

echo
echo "✓ Built: ${APP_DIR}"
echo "  Open with: open \"${APP_DIR}\""
