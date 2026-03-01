# StatusBarCountdown

Simple macOS status bar countdown app built with Swift and AppKit.

## Run

```bash
cd /Users/tructt/Public/Projects/StatusBarCountdown
swift run
```

Optional: pass initial countdown minutes.

```bash
swift run StatusBarCountdown 15
```

Default countdown is 25 minutes.

## Build .app (with icon)

Generate icon assets:

```bash
cd /Users/tructt/Public/Projects/StatusBarCountdown
swift scripts/generate_app_icon.swift Assets/AppIcon.iconset
iconutil -c icns Assets/AppIcon.iconset -o Assets/AppIcon.icns
```

Package local app bundle:

```bash
cd /Users/tructt/Public/Projects/StatusBarCountdown
# Default is Apple Silicon optimized build (arm64)
./scripts/package_app.sh
open /Users/tructt/Public/Projects/StatusBarCountdown/dist/StatusBarCountdown.app
```

Create release artifacts (`.zip` + `.dmg`):

```bash
cd /Users/tructt/Public/Projects/StatusBarCountdown
# Creates:
# - dist/StatusBarCountdown-apple-silicon.zip
# - dist/StatusBarCountdown-apple-silicon.dmg
./scripts/create_release_artifacts.sh
```

Optional universal build (Apple Silicon + Intel):

```bash
cd /Users/tructt/Public/Projects/StatusBarCountdown
ARCH_MODE=universal ./scripts/create_release_artifacts.sh
```

Optional notarization flow (requires `Developer ID Application` cert and a Notary keychain profile):

```bash
cd /Users/tructt/Public/Projects/StatusBarCountdown
NOTARIZE=1 NOTARY_PROFILE="YOUR_PROFILE" ./scripts/package_app.sh
```

## Features

- Countdown shown in macOS status bar (menu bar)
- Reset timer to initial value
- Add custom quick time from settings
- Simplified macOS-style settings form (clear labels + grouped sections)
- Preset selector (`Pomodoro`, `Deep Work`, `Sprint`)
- Inline validation + `Reset Defaults`
- Optional `Apply and reset timer immediately` when saving
- Settings UI to change:
  - default countdown minutes
  - quick add minutes
  - play sound on finish
  - bounce app icon on finish
- Persist settings with `UserDefaults`
- Sound + attention request when time is up
- Quit from status bar menu
