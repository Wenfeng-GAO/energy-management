# Energy Management

Energy Management is a native iOS sleep coach MVP. It helps a user define a bedtime, wake-up time, and bedtime preparation lead time, then uses local reminders and manual confirmations to show daily and seven-day schedule signals.

## MVP Scope

- SwiftUI iOS app with local-only manual routine data.
- First-run schedule setup, bedtime preparation, wake confirmation, daily report, and seven-day trend.
- Simplified Chinese user-facing copy for the first version.
- Minimal Japanese/Scandinavian-inspired visual direction with warm whites, warm grays, restrained typography, and low-noise interaction states.
- Reports must describe estimated sleep opportunity and schedule consistency, not measured sleep duration or clinical sleep quality.
- Local notifications can remind the user before bedtime preparation and around wake time, but the app remains usable when notifications are disabled.

## Privacy Boundaries

The MVP does not include HealthKit, WeatherKit, location, accounts, StoreKit, widgets, export, cloud sync, server services, or social sharing. Data should remain on device and be based on manual settings and confirmations.

## Manual QA Checklist

- First launch shows setup in Simplified Chinese with warm white / warm gray styling.
- Setup saves bedtime, wake time, and preparation lead time, then routes to today’s rhythm.
- Notification-denied and not-yet-requested states show non-blocking copy.
- Bedtime preparation suggestions render as guidance, not a checklist.
- Wake confirmation is available only within the wake window and shows prompts after confirmation.
- Missed wake state uses estimated/missed language and does not allow late on-time confirmation.
- Reports show estimated sleep opportunity, wake signal, seven-day trend, and the schedule-based disclaimer.
- Large Dynamic Type keeps primary actions visible and tappable.
- Reduced motion does not rely on disruptive transitions.
- App icon and launch screen use the warm Japanese/Scandinavian visual direction.

## Development

This repository uses XcodeGen to generate `EnergyManagement.xcodeproj` from `project.yml`.

```sh
xcodegen generate
xcodebuild test -project EnergyManagement.xcodeproj -scheme EnergyManagement -destination 'platform=iOS Simulator,name=iPhone 16'
```

Current implementation source of truth: `docs/plans/2026-06-04-001-feat-sleep-coach-mvp-plan.md`.
