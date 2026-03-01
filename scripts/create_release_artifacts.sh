#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="${APP_NAME:-StatusBarCountdown}"
ARCH_MODE="${ARCH_MODE:-arm64}" # arm64|universal|x86_64
RELEASE_SUFFIX="${RELEASE_SUFFIX:-}"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"

if [[ -z "$RELEASE_SUFFIX" ]]; then
    case "$ARCH_MODE" in
        arm64) RELEASE_SUFFIX="-apple-silicon" ;;
        x86_64) RELEASE_SUFFIX="-intel" ;;
        universal) RELEASE_SUFFIX="-universal" ;;
        *) echo "Invalid ARCH_MODE: $ARCH_MODE (expected: arm64|x86_64|universal)" >&2; exit 1 ;;
    esac
fi

ZIP_PATH="$DIST_DIR/$APP_NAME$RELEASE_SUFFIX.zip"
DMG_PATH="$DIST_DIR/$APP_NAME$RELEASE_SUFFIX.dmg"

cd "$ROOT_DIR"

ARCH_MODE="$ARCH_MODE" "$ROOT_DIR/scripts/package_app.sh"

rm -f "$ZIP_PATH" "$DMG_PATH"

echo "[$APP_NAME] Creating ZIP..."
ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ZIP_PATH"

echo "[$APP_NAME] Creating DMG..."
hdiutil create -volname "$APP_NAME" -srcfolder "$APP_DIR" -ov -format UDZO "$DMG_PATH" >/tmp/"$APP_NAME"_dmg.log
tail -n 5 /tmp/"$APP_NAME"_dmg.log || true

echo "[$APP_NAME] Release artifacts:"
ls -lh "$ZIP_PATH" "$DMG_PATH"
