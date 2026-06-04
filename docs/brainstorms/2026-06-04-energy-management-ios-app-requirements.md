---
date: 2026-06-04
topic: energy-management-ios-app
---

# Energy Management iOS App Requirements

## Problem Frame

Busy users often know that sleep affects next-day energy, but they lack a lightweight system that turns a planned bedtime into a practical wind-down routine, makes waking up an intentional action, and reflects sleep consistency back in a way that is beautiful enough to keep using.

The first version should be a quiet, Japanese/Scandinavian-inspired iOS sleep coach: simple to configure, calming at night, crisp in the morning, and useful without requiring Apple Health integration on day one.

## Requirements

**Schedule Setup**
- R1. The app must provide a short first-run setup flow covering notification permission explanation, target bedtime, target wake-up time, and bedtime preparation lead time.
- R2. The app must let the user set a target bedtime.
- R3. The app must let the user set a bedtime preparation lead time, such as 15, 30, 45, or 60 minutes before bedtime.
- R4. The app must let the user set a target wake-up time.
- R5. The app must present the current sleep schedule in a compact, easy-to-scan home view.
- R6. If notification permission is disabled, the app must show a persistent, low-noise in-app prompt explaining that reminders need notification permission.

**Bedtime Preparation**
- R7. When the bedtime preparation window starts, the app must remind the user to begin winding down.
- R8. The bedtime preparation reminder must include concrete, low-friction suggestions such as moving away from screens, dimming lights, cooling the bedroom, preparing tomorrow's essentials, and doing a short calming routine.
- R9. The bedtime preparation experience should feel calm and minimal, with optional guidance rather than a required checklist.
- R10. The app may include a simple "I'm preparing for sleep" or "I'm going to bed" action, but this must be framed as a bedtime confirmation rather than a measured actual sleep time.

**Wake-Up Confirmation**
- R11. Around the target wake-up time, the app must ask the user to confirm that they are awake.
- R12. The wake-up confirmation must be a simple, prominent action, such as a single "I'm awake" button.
- R13. The wake-up confirmation should support natural early waking, allowing confirmation shortly before the target wake-up time as well as after it.
- R14. If the user does not confirm waking within a reasonable post-wake window, the app must mark the day as missed or estimated in reports rather than silently treating the schedule as confirmed.
- R15. After confirmation, the app must show short prompts that help the user become alert, such as drinking water, opening curtains, standing up, stretching briefly, or avoiding phone scrolling.

**Sleep Reporting**
- R16. The app must generate a daily sleep report from the configured bedtime, target wake-up time, whether bedtime preparation guidance was delivered, and wake-up confirmation time.
- R17. The daily report must show estimated sleep opportunity, wake-up punctuality, and a concise recovery or rhythm suggestion for the day.
- R18. The app must show a seven-day trend view with average estimated sleep opportunity, wake-up consistency, and consecutive days meeting the user's schedule.
- R19. The report experience must be visually polished and easy to understand at a glance, prioritizing clear hierarchy over dense analytics.
- R20. Report metrics must be clearly framed as estimates or schedule-based signals, not as measured sleep-stage or medical-quality sleep data.

**Design and Experience**
- R21. The first version must use a minimalist Japanese/Scandinavian visual direction: warm gray and warm white as the base, low-saturation blue or green as accents, restrained layout, generous spacing, refined typography, soft corners, and subtle motion.
- R22. Nighttime surfaces may use gentle darker tones or ambient treatment, but the overall app should remain clean, warm, modern, and not visually heavy.
- R23. The app must meet basic accessibility expectations: clear VoiceOver labels, Dynamic Type support, 44pt minimum touch targets, sufficient color contrast, and respect for reduced motion settings.
- R24. The app must cover key interaction states, including notification permission disabled, first-week data accumulation, missed wake confirmation, and unavailable reminder/report data.
- R25. The app must avoid turning into a broad productivity or habit tracker in the first version.

**Data and Privacy**
- R26. The first version must work with manual app data only, without requiring Apple Health or external accounts.
- R27. The product direction must leave room for future HealthKit integration to improve sleep-data accuracy, but HealthKit is not required for the MVP.

## Success Criteria

- A user can configure bedtime, preparation lead time, and wake-up time in one short flow.
- The user receives a useful bedtime preparation reminder before the target bedtime.
- The user can confirm waking up with one clear action.
- The app generates a daily report that feels rewarding rather than clinical.
- The app shows a weekly trend that makes sleep consistency visible without overwhelming the user.
- The app handles common imperfect behavior gracefully, including disabled notifications and missed wake confirmations.
- The app can be planned and implemented as a focused MVP without requiring HealthKit, accounts, or broad habit tracking.

## Scope Boundaries

- No HealthKit integration in the first version.
- No account system, cloud sync, social sharing, or multi-device behavior in the first version.
- No WeatherKit, location permission, quote feed, or morning news-style briefing in the first version.
- No in-app purchase, paid feature gating, long-image sharing, CSV/PDF export, monthly report, yearly report, or widget in the first version.
- No detailed sleep-stage analysis, sleep score model, or medical claims.
- No claim that the app measures actual sleep duration unless a future version integrates a real sleep-data source.
- No broad daytime productivity tracker, energy diary, caffeine tracker, workout tracker, or mood tracker.
- No complex bedtime checklist required for MVP; suggestions are guidance, not mandatory task completion.

## Key Decisions

- Product positioning: Build a lightweight sleep coach, not a full energy-management platform. This keeps the first version focused and makes quality easier to achieve.
- Data source: Use manual app data first, while preserving the product path for future HealthKit support. This reduces MVP complexity and privacy friction.
- Reporting depth: Include daily reports plus seven-day trends. This provides enough feedback value without turning the app into an analytics dashboard.
- Visual direction: Use a minimalist Japanese/Scandinavian style centered on warm gray and warm white. This makes the app feel calm, designed, and daily-usable without relying on heavy decoration.
- MVP detail absorption: Keep first-run setup, early/late wake confirmation tolerance, missed-confirmation report handling, accessibility, and key empty/error states from the broader sleep-ritual draft because they improve quality without changing the product into a larger platform.

## Dependencies / Assumptions

- The app targets iOS users and can rely on local notifications for bedtime preparation and wake-up-related prompts.
- Sleep opportunity in the MVP is estimated from configured bedtime and wake-up confirmation behavior, not measured sleep stages.
- The user values visual polish and calm guidance more than quantified sleep science in the first version.

## Outstanding Questions

### Resolve Before Planning

- None.

### Deferred to Planning

- [Affects R7, R11][Technical] Decide the exact notification behavior, including repeat cadence, snooze behavior, and exact wake-confirmation timing window.
- [Affects R16, R18][Technical] Decide how local sleep records are stored and how missed confirmations are represented in reports.
- [Affects R21, R22][Design] Produce the concrete visual system, screen inventory, and interaction states.

## Next Steps

-> /ce:plan for structured implementation planning
