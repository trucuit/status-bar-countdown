# Install Checklist (macOS)

Updated: 2026-03-01
App: `/Users/tructt/Public/Projects/StatusBarCountdown/dist/StatusBarCountdown.app`

## 1) Build & Bundle

- [x] App bundle exists (`.app`)
- [x] `Info.plist` present and readable
- [x] `CFBundleIdentifier` set (`com.tructt.StatusBarCountdown`)
- [x] `LSMinimumSystemVersion` set (`13.0`)
- [x] App icon embedded (`CFBundleIconFile = AppIcon`, `Resources/AppIcon.icns` exists)

## 2) CPU / Compatibility

- [x] Built for Apple Silicon (`arm64`)
- [ ] Built for Intel (`x86_64`)
- [ ] Universal binary (`arm64 + x86_64`)

Current result:
- Default release mode is Apple Silicon optimized.
- `lipo -archs` => `arm64`
- If needed, build universal via `ARCH_MODE=universal`.

## 3) Signing / Gatekeeper / Notarization

- [x] Code signature verifies (`codesign --verify --deep --strict`)
- [ ] Signed with Apple Developer ID Application certificate
- [x] Hardened Runtime enabled
- [ ] Notarized by Apple
- [ ] Stapled notarization ticket
- [ ] Gatekeeper assessment passes (`spctl --assess`)

Current result:
- Signature authority: `Apple Development: Truc Tran (N83R4TT9XX)`
- Runtime flag: enabled (`flags=0x10000(runtime)`)
- `spctl --assess` => `rejected`
- `xcrun stapler validate` => no stapled ticket
- `Developer ID Application` certificate: not found on current machine

## 4) Distribution Readiness

- [x] ZIP/DMG packaging flow for sharing
- [ ] Clean install test on a second Mac (fresh user)
- [ ] Upgrade test from previous version
- [ ] Uninstall/reinstall test

Current result:
- `/Users/tructt/Public/Projects/StatusBarCountdown/dist/StatusBarCountdown-apple-silicon.zip` created
- `/Users/tructt/Public/Projects/StatusBarCountdown/dist/StatusBarCountdown-apple-silicon.dmg` created

## Verdict

Current status: **PARTIALLY READY**.

What works now:
- Fast build optimized for Apple Silicon.
- Signed and packaged (`.app`, `.zip`, `.dmg`).
- Suitable for internal sharing with manual Gatekeeper bypass.

What is missing for production-like install:
- Developer ID Application signing
- Notarization + stapling
- Optional universal build if you want Intel support
- Clean install verification on another Mac

## Quick temporary workaround (internal testing only)

On target Mac (after copy app):

```bash
xattr -dr com.apple.quarantine /path/to/StatusBarCountdown.app
open /path/to/StatusBarCountdown.app
```

Or right-click app in Finder -> `Open` -> `Open`.
