---
author: opencode
date: 2026-11-04
task: TASK-007
---

# TASK-007 — Explore UI: thumbnails and day selector (weekday trending)

## Status
- [x] Planned
- [x] In progress
- [x] QA
- [x] Review
- [x] Done

## Goal
When this task is done, the Explore tab shows a grid of show cards with thumbnails (poster + fallback icon), a horizontally scrollable day selector (Mon-Sun), selecting a day loads that day's top 7 trending titles, and the selected day syncs with device weekday on first load.

## Scope

**In scope**
- Explore screen (currently SearchScreen): new layout "Explore", keep SearchRoute optional.
- Day selector: Monday..Sunday chips; selected weekday highlights; changes content.
- Show cards: thumbnail (poster). Reuse CachedNetworkImage with placeholder + errorWidget; title (max 2 lines) and EP badge.
- Data source stays provider `search('')` with the current cycle weekday index; day selector queries per-day (`_scrapeWeekdayTrending` extended to accept ISO day or offset).
- Persist the last viewed weekday (optional); fallback when no network.

**Out of scope**
- Implementing per-day real network data (still derived from home page; cached).
- New packages.
- Recreating search bar in the new UI (Explore shows featured trending).

## Acceptance criteria
- [ ] Explore renders >=7 cards for each available day with thumbnails visible or icon fallback.
- [ ] Chip selection changes the visible cards (7 items expected) and highlights the chip.
- [ ] Switching weekday reacts under 1 sec after data available (uses persisted cache).
- [ ] No crash when a poster URL returns 404 (errorWidget icon shown).
- [ ] `flutter analyze` clean, tests pass.

## Plan
1. Create `ExploreScreen` widget from SearchScreen's current content (move content to new file `lib/features/explore/explore_screen.dart`).
2. Introduce a weekday-based provider/channel: `streamProvider.episodes` reuse; ask `search('')` with an optional `_weekday` query. Could expose method `_scrapeWeekdayTrending(day)`.
3. Build the day chips, grid of 7 cards.
4. Update `main_screen.dart` to use ExploreScreen as tab 0.
5. Run format, analyze, test; update widget_test.

## Risks
- Decoupling search from Explore may break tests (mock provider search).
- Weekday caching per day adds state management; start with in-memory cache map keyed by `DateTime.weekday`.
- If scrapped articles less than 7 on a day, fall back to the built-in pool.

## Notes
- `TASK-005` introduced the weekday trending in provider; this UI task surfaces it.
- Do not push without approval.
