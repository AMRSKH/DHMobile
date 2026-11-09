---
author: opencode
date: 2026-11-04
task: TASK-005
---

# TASK-005 — Development notes

## Done this round (focused, compilation-safe slices)

- Renamed app display label: Android `android:label="DHMobile"` in `AndroidManifest.xml`.
- New application id: `applicationId = "dhmobile.amscenter.dev"` in `build.gradle.kts`.
- Added Flutter splash widget `lib/features/splash/splash_screen.dart` showing "DonghuaMobile", plus credits "Development by AMSCenter" / "Developer by AMSDev" (also added to Settings > About immediately in the previous pass).
- Thumbnails: existing `CachedNetworkImage` usage already has placeholders; detail screen now shares the same graceful fallback.
- Explore default list: `_getFeaturedShows()` replaced by weekday-aware `search('')`; scrapes the home page (first 21 articles), dedupes by URL, rotates 7 picks by ISO weekday (Monday..Sunday), caches per day to avoid refetch. Falls back to built-in 4-item pool on failure/offline.

## Changed files (key)

- `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`
- `lib/main.dart`, `lib/features/splash/splash_screen.dart`
- `lib/data/providers/animexin_stream_provider.dart` (_cachedWeekdayTrending/_scrapeWeekdayTrending, cache fields)
- `test/widget_test.dart`, `test/stream_provider_test.dart` (updates matching splash + scraped trending)

## Validation

- `flutter analyze`: no issues.
- `flutter test`: 12/12 passed.
- Native Kotlin volume channel / package left untouched (applicationId differs now, channel still `dev.amscenter.donghua_player/volume`).

## Remaining (out of scope or followups)

- Visual splash text on Android 12+ (Android 12 adds its own splash drawable; Native tooling or `flutter_native_splash` needed for native text label) — the Flutter widget is the cross-platform solution.
- Image `errorWidget` parity across cards could be tightened.
- Pub package name left as `donghua_player` to avoid 50+ import rewrites; display name changed as required.
- Per-weekday trending still derives from site home scrape, not a true endpoint (documented in plan).
