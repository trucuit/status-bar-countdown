#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="${APP_NAME:-StatusBarCountdown}"
APP_BUNDLE_ID="${APP_BUNDLE_ID:-com.tructt.StatusBarCountdown}"
APP_VERSION="${APP_VERSION:-1.0}"
APP_BUILD="${APP_BUILD:-1}"
MIN_MACOS="${MIN_MACOS:-13.0}"
ARCH_MODE="${ARCH_MODE:-arm64}" # arm64|universal|x86_64
SIGN_MODE="${SIGN_MODE:-auto}" # auto|none|adhoc
SIGN_IDENTITY="${SIGN_IDENTITY:-${APPLE_SIGN_IDENTITY:-}}"
NOTARIZE="${NOTARIZE:-0}" # 1 to notarize+staple
NOTARY_PROFILE="${NOTARY_PROFILE:-${NOTARY_KEYCHAIN_PROFILE:-}}"
STRICT_GATEKEEPER="${STRICT_GATEKEEPER:-0}" # 1 to fail build when spctl rejects

DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICON_PATH="$ROOT_DIR/Assets/AppIcon.icns"

cd "$ROOT_DIR"

log() { echo "[$APP_NAME] $*"; }

resolve_binary_path() {
    local mode="$1"
    case "$mode" in
        arm64)
            if [[ -f "$ROOT_DIR/.build/arm64-apple-macosx/release/$APP_NAME" ]]; then
                echo "$ROOT_DIR/.build/arm64-apple-macosx/release/$APP_NAME"
                return
            fi
            ;;
        x86_64)
            if [[ -f "$ROOT_DIR/.build/x86_64-apple-macosx/release/$APP_NAME" ]]; then
                echo "$ROOT_DIR/.build/x86_64-apple-macosx/release/$APP_NAME"
                return
            fi
            ;;
        universal)
            if [[ -f "$ROOT_DIR/.build/apple/Products/Release/$APP_NAME" ]]; then
                echo "$ROOT_DIR/.build/apple/Products/Release/$APP_NAME"
                return
            fi
            ;;
    esac

    if [[ -f "$ROOT_DIR/.build/release/$APP_NAME" ]]; then
        echo "$ROOT_DIR/.build/release/$APP_NAME"
        return
    fi

    echo ""
}

pick_sign_identity() {
    if [[ "$SIGN_MODE" == "none" ]]; then
        echo ""
        return
    fi

    if [[ "$SIGN_MODE" == "adhoc" ]]; then
        echo "-"
        return
    fi

    if [[ -n "$SIGN_IDENTITY" ]]; then
        echo "$SIGN_IDENTITY"
        return
    fi

    local dev_id
    dev_id="$(security find-identity -v -p codesigning 2>/dev/null | awk -F\" '/Developer ID Application/ {print $2; exit}')"
    if [[ -n "$dev_id" ]]; then
        echo "$dev_id"
        return
    fi

    local apple_dev
    apple_dev="$(security find-identity -v -p codesigning 2>/dev/null | awk -F\" '/Apple Development:/ {print $2; exit}')"
    if [[ -n "$apple_dev" ]]; then
        echo "$apple_dev"
        return
    fi

    echo "-"
}

case "$ARCH_MODE" in
    arm64)
        log "Building optimized binary for Apple Silicon (arm64)"
        swift build -c release --arch arm64
        ;;
    x86_64)
        log "Building binary for Intel (x86_64)"
        swift build -c release --arch x86_64
        ;;
    universal)
        log "Building universal binary (arm64 + x86_64)"
        swift build -c release --arch arm64 --arch x86_64
        ;;
    *)
        echo "Invalid ARCH_MODE: $ARCH_MODE (expected: arm64|x86_64|universal)" >&2
        exit 1
        ;;
esac

mkdir -p "$DIST_DIR" "$MACOS_DIR" "$RESOURCES_DIR"
SOURCE_BINARY="$(resolve_binary_path "$ARCH_MODE")"
if [[ -z "$SOURCE_BINARY" ]]; then
    echo "Cannot find release binary." >&2
    exit 1
fi
cp "$SOURCE_BINARY" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>__APP_NAME__</string>
    <key>CFBundleIdentifier</key>
    <string>__APP_BUNDLE_ID__</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>__APP_NAME__</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>__APP_VERSION__</string>
    <key>CFBundleVersion</key>
    <string>__APP_BUILD__</string>
    <key>LSMinimumSystemVersion</key>
    <string>__MIN_MACOS__</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
PLIST

perl -0pi -e "s/__APP_NAME__/$APP_NAME/g; s/__APP_BUNDLE_ID__/$APP_BUNDLE_ID/g; s/__APP_VERSION__/$APP_VERSION/g; s/__APP_BUILD__/$APP_BUILD/g; s/__MIN_MACOS__/$MIN_MACOS/g;" "$CONTENTS_DIR/Info.plist"

if [[ -f "$ICON_PATH" ]]; then
    cp "$ICON_PATH" "$RESOURCES_DIR/AppIcon.icns"
fi

SIGN_IDENTITY="$(pick_sign_identity)"
if [[ "$SIGN_MODE" == "none" ]]; then
    log "Skipping code signing (SIGN_MODE=none)"
elif [[ "$SIGN_IDENTITY" == "-" ]]; then
    log "Signing with ad-hoc identity"
    codesign --force --deep --sign - "$APP_DIR"
else
    log "Signing with identity: $SIGN_IDENTITY"
    codesign --force --deep --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP_DIR"
fi

if [[ "$SIGN_MODE" != "none" ]]; then
    codesign --verify --deep --strict --verbose=2 "$APP_DIR"
fi

if [[ "$NOTARIZE" == "1" ]]; then
    if [[ -z "$NOTARY_PROFILE" ]]; then
        echo "NOTARIZE=1 but NOTARY_PROFILE is empty." >&2
        exit 1
    fi
    if [[ "$SIGN_IDENTITY" == "-" ]] || [[ "$SIGN_IDENTITY" == Apple\ Development:* ]]; then
        echo "Notarization requires a Developer ID Application signing identity." >&2
        exit 1
    fi
    log "Submitting app for notarization..."
    xcrun notarytool submit "$APP_DIR" --keychain-profile "$NOTARY_PROFILE" --wait
    log "Stapling notarization ticket..."
    xcrun stapler staple "$APP_DIR"
    xcrun stapler validate "$APP_DIR"
fi

log "Architecture(s): $(lipo -archs "$MACOS_DIR/$APP_NAME")"

if spctl --assess --type execute --verbose=4 "$APP_DIR" >/tmp/"$APP_NAME"_spctl.log 2>&1; then
    log "Gatekeeper assessment: accepted"
else
    log "Gatekeeper assessment: rejected"
    cat /tmp/"$APP_NAME"_spctl.log
    if [[ "$STRICT_GATEKEEPER" == "1" ]]; then
        exit 1
    fi
fi

log "Packaged: $APP_DIR"
