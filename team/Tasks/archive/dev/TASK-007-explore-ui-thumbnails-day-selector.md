---
author: opencode
date: 2026-11-04
task: TASK-007
---

# TASK-007 — Development notes

## Implemented

- New `lib/features/explore/explore_controller.dart` exposes `selectedWeekday` and `selectWeekday(day)`; loads via provider `search('', weekday: day)`.
- New `lib/features/explore/explore_screen.dart`: day chips (Mon..Sun), 2-column grid of poster cards with `CachedNetworkImage` placeholder + error icon; EP count subtitle; tap opens detail. Refresh button re-runs the selected weekday.
- New `DonghuaStreamProvider.search` optional `{weekday}` param and `AnimeXinStreamProvider` weekday rotation of 7 picks from the scraped home pool (day 1..7).
- `main_screen.dart`: Explore tab now uses `ExploreScreen`.

## Validation
- `flutter analyze`: no issues.
- `flutter test`: 12/12 pass.

## Notes
- Article count target 7 per weekday; pool uses first 21 scraped articles (rotated 7 by ISO weekday), so different days usually differ, but a site change can yield less.
- UI not wired to main navigation refresh indicator; no deprecation of SearchScreen, still available if needed.
- No runtime build this round (pre-release qa not attempted).
