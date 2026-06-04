---
date: 2026-06-04
status: passed
---

# Xcode Validation Notes

## Goal

Install full Xcode and validate the Energy Management iOS app with the available iOS build plugin/tooling.

## Current State

- Repository is synced to `origin/main` at `112702a`.
- The app implementation exists under `EnergyManagement/`.
- Peter reported the latest completed baseline as `38 unit tests + 14 UI tests`.
- Current validation host has full Xcode selected:
  - `xcode-select -p` -> `/Applications/Xcode.app/Contents/Developer`
  - `xcodebuild -version` -> `Xcode 16.4`, build `16F6`
  - `xcrun --find xcodebuild` -> `/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild`
  - `xcrun --find simctl` -> `/Applications/Xcode.app/Contents/Developer/usr/bin/simctl`
- The requested `build-ios-apps` plugin is not currently available in this Codex session. The available iOS build capability is XcodeBuildMCP, which also requires full Xcode.

## Automated Validation

Validated on 2026-06-04 with:

```console
xcodegen generate
xcodebuild test -project EnergyManagement.xcodeproj -scheme EnergyManagement -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'
```

Result:

- `xcodegen generate` exits 0.
- `xcodebuild test` exits 0.
- `** TEST SUCCEEDED **`
- `38 unit tests + 14 UI tests` pass with 0 failures.

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
