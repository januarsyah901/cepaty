#!/bin/bash
set -e

APP_NAME="Cepaty"
APP_DIR="${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
SDK_PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"
TARGET="arm64-apple-macosx13.0"

echo "=== Membangun binary ${APP_NAME} ==="
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

swiftc -O -whole-module-optimization \
    -sdk "${SDK_PATH}" \
    -target "${TARGET}" \
    Sources/Cepaty/CepatyApp.swift \
    Sources/Cepaty/Core/*.swift \
    Sources/Cepaty/ViewModels/*.swift \
    Sources/Cepaty/Views/*.swift \
    Sources/Cepaty/Utils/*.swift \
    -o "${MACOS_DIR}/${APP_NAME}"

echo "=== Menyiapkan bundle ${APP_DIR} ==="
if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "${RESOURCES_DIR}/AppIcon.icns"
fi

cat << 'EOF' > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Cepaty</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.cepaty.menubar</string>
    <key>CFBundleName</key>
    <string>Cepaty</string>
    <key>CFBundleDisplayName</key>
    <string>Cepaty</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "=== Memberi kode signing ad-hoc ==="
codesign --force --deep --sign - "${APP_DIR}"

echo "=== Membuat DMG Installer ==="
hdiutil create -volname "${APP_NAME}" -srcfolder "${APP_DIR}" -ov -format UDZO "${APP_NAME}-1.0.0.dmg"

echo "=== Memasang ${APP_NAME}.app ke /Applications ==="
rm -rf "/Applications/${APP_DIR}"
cp -R "${APP_DIR}" "/Applications/${APP_DIR}"

echo "Selesai! ${APP_NAME}.app terpasang di /Applications/${APP_DIR}"
