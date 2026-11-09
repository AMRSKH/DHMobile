---
author: opencode
date: 2026-11-04
task: TASK-005
---

# TASK-005 — Rename app (DHMobile / dhmobile.amscenter.dev), splash text, thumbnails, and weekday-trending explore list

## Status
- [x] Planned
- [x] In progress
- [ ] QA
- [ ] Review
- [ ] Done

## Goal
When the task is complete the user sees "DHMobile" as the app label and "DonghuaMobile" on the Android splash, the app ships under `dhmobile.amscenter.dev`, every movie/show card (home, search, detail) renders a real poster thumbnail, and the Explore tab's default (no query) list shows the top 7 trending titles for the current weekday (Monday-Sunday).

## Scope

**In scope**
- Display name: `DHMobile` (Android `applicationName`, iOS `CFBundleDisplayName`, launcher label).
- ApplicationId / package change: `dhmobile.amscenter.dev` (Android `applicationId`, `namespace`, iOS bundle id, Kotlin package path, MethodChannel `dev.amscenter.donghua_player/volume` → `dhmobile.amscenter.dev/volume`).
- Splash screen text: `DonghuaMobile` (native splash or Flutter splash widget), plus a credit line "Development by AMSCenter" / "Developer by AMSDev" (splash or Settings > About)."
- Thumbnails for all shows: ensure `Show.poster` is parsed from every card (`img data-src/src`, `srcset` best resolution) and cached; add placeholder and graceful fallback.
- Explore default list: top 7 trending per weekday. Define source and weekday mapping (Monday..Sunday), cache per ISO day so it does not refetch each session.

**Out of scope**
- App store / Play Store migration (existing app id has installs, sideload only).
- New network data source if the site does not expose a trending endpoint (use scraper-derived or local ranking).
- Dark/light theme adjustments beyond the splash text.

## Acceptance criteria
- [ ] `flutter run` installs as `dhmobile.amscenter.dev` and the launcher icon label reads "DHMobile".
- [ ] Splash screen shows "DonghuaMobile" (screenshot-verified or uiautomator dump of `android.widget.TextView`).
- [ ] An About/Settings entry or splash footer shows "Development by AMSCenter" and "Developer by AMSDev".
- [ ] `flutter analyze` clean, no `package:donghua_player` import path regressions after the package rename.
- [ ] Every show card in Home, Search, and Detail renders a non-empty poster (`cached_network_image` placeholder shown while loading) — regression-checked versus 5 titles.
- [ ] Explore default view (no active query) shows exactly 7 cards, each tagged with the matching weekday's trending rank, and changes when the device day changes (verified by mocking weekday and the forced rotation `user_rotation`).
- [ ] No crash on app upgrade from `dev.amscenter.donghua_player` (migration path documented; out-of-scope is data).

## Plan
1. Read existing `flutter_vlc_player`/`MethodChannel` usage, `AndroidManifest.xml`, `build.gradle`, `Info.plist`, and `main.dart` to enumerate every place the old name/id leaks (`DevPro\DHMobile` git grep for `donghua_player` / `amscenter`).
2. Rename the package folder and `package` declarations; update the `volume` `MethodChannel` strings on both Kotlin and Dart sides; update `pubspec.yaml` name if desired while preserving imports.
3. Add/configure native splash (Android `drawable/splash.xml` + `styles.xml`) showing "DonghuaMobile" text, using the white `#FFFFFF` background already chosen for the icon.
4. Audit the scraper for poster extraction; normalize to `https` absolute URLs; add an `errorWidget` fallback icon to every `CachedNetworkImage` (home, search, detail, player placeholder).
5. Define the weekday trending source: if `animexin.dev` exposes a day filter, scrape it; otherwise fall back to the latest 7 featured items per screen day; cache via Hive under `trending_<weekday>`.
6. Update Explore screen: default query maps to the current weekday's top-7 list; allow manual weekday override for QA.
7. Re-run `dart format`, `flutter analyze`, `flutter test`; build and side-load; verify on.device via `flutter run` and `uiautomator dump`.

## Risks
- ApplicationId change looks like a fresh app to Android (users need to reinstall; do not auto-migrate).
- Package rename is wide; missing one import breaks the build. Mitigate with search for `package:.*donghua_player`.
- Splash text sizing across OS API levels needs QA on API 37.
- If the site does not expose per-day trending, the contract must gracefully fall back (top recent titles); document this decision in `.team/advisor`.
- Thumbnail 404s must be swallowed by placeholder widgets (avoid blank white boxes).

## Notes
- Source task for rename and trend content is this request (created 2026-11-04).
- `flutter pub get` requires user approval before running during implementation.
