---
date: 2026-06-04
status: blocked-by-xcode-install
---

# Xcode Validation Notes

## Goal

Install full Xcode and validate the Energy Management iOS app with the available iOS build plugin/tooling.

## Current State

- Repository is synced to `origin/main` at `68a3672`.
- The app implementation exists under `EnergyManagement/`.
- Peter reported the latest completed baseline as `38 unit tests + 14 UI tests`.
- Current machine only has Command Line Tools selected:
  - `xcode-select -p` -> `/Library/Developer/CommandLineTools`
- Current machine does not have `/Applications/Xcode.app`.
- `xcrun --find xcodebuild` and `xcrun --find simctl` fail because full Xcode is not installed.
- The requested `build-ios-apps` plugin is not currently available in this Codex session. The available iOS build capability is XcodeBuildMCP, which also requires full Xcode.

## Installation Blocker

Full Xcode installation requires an Apple installation path that is not currently automatable here:

- App Store install requires Apple ID / App Store authorization.
- `softwareupdate --list` does not offer Xcode.
- Homebrew is currently unable to fetch formula metadata from `formulae.brew.sh`, so `mas` / `xcodes` cannot be installed through Homebrew in this session.

## Continue After Xcode Is Installed

After `/Applications/Xcode.app` exists and has been opened once to finish first-run setup:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
xcodebuild -version
xcrun --find simctl
xcodegen generate
xcodebuild test -project EnergyManagement.xcodeproj -scheme EnergyManagement -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'
```

Expected automated result:

- `xcodebuild test` exits 0.
- Existing unit tests and UI tests pass.
- Baseline to compare against: `38 unit tests + 14 UI tests`.

## Manual QA Target

Use `README.md` as the manual QA checklist:

- First launch shows setup in Simplified Chinese with warm white / warm gray styling.
- Setup saves bedtime, wake time, and preparation lead time, then routes to today's rhythm.
- Notification-denied and not-yet-requested states show non-blocking copy.
- Bedtime preparation suggestions render as guidance, not a checklist.
- Wake confirmation is available only within the wake window and shows prompts after confirmation.
- Missed wake state uses estimated/missed language and does not allow late on-time confirmation.
- Reports show estimated sleep opportunity, wake signal, seven-day trend, and the schedule-based disclaimer.
- Large Dynamic Type keeps primary actions visible and tappable.
- Reduced motion does not rely on disruptive transitions.
- App icon and launch screen use the warm Japanese/Scandinavian visual direction.

## Scope Invariants

Validation should not introduce or require:

- HealthKit
- WeatherKit
- Location permission
- Account system
- StoreKit
- Widgets
- Export
- Cloud sync
- Medical or actual-sleep measurement claims
