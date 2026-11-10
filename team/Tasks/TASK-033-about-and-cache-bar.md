Author: AI Agent
Date: 2026-11-10
Task: TASK-033
Status: In Review

# TASK-033: New About section and a cache size bar

## Objective

Show About exactly in the owner's layout, and show the real size of the
app's cache as a bar (500 MB scale) on Clear Cache, with automatic cleaning
above 500 MB.

## Background

Owner `/task`, 2026-11-10:

```text
ABOUT
DHMobile
Version x.x.x (build x)
Credits
Player | ExoPlayer, VLC
Contents | DonghuaCLI
Development
AMSCenter by AMSDev
Privacy
No ads.
No tracking.
History and favorites
are stored only on this device.
```

"and Update Cache to has bar size of it cache storage."

Owner choices (2026-11-10): bar against a 500 MB limit, and the app clears
the cache by itself on start when it is above 500 MB; About shows only the
owner's layout (the separate "Player" and "Content source" rows go; the
player choice stays in Settings > Video Player).

Found while planning: `StorageService.clearAllCache()` clears only the image
cache in memory (`PaintingBinding.imageCache`); the posters that
`cached_network_image` keeps on disk were never deleted.

## Requirements

1. About: DHMobile + version line; Credits with "Player | ExoPlayer, VLC" and
   "Contents | DonghuaCLI"; Development "AMSCenter by AMSDev"; Privacy in the
   owner's line breaks. English and Khmer for the app's own words; product
   names stay.
2. Clear Cache shows the size of the app's cache folder ("86.4 MB / 500 MB")
   and a bar; the bar is red near the limit.
3. Clear Cache deletes the files in the cache folder (and the memory cache),
   then shows the new size.
4. On start, a cache above 500 MB is cleared by itself.
5. No new package: the cache folder is `Directory.systemTemp`, which Flutter
   sets to the app's cache directory on Android (to be checked on the phone).

## Scope

`lib/features/settings/settings_screen.dart`, `settings_controller.dart`,
`lib/data/storage/storage_service.dart` (or a new cache service),
`lib/core/l10n/app_strings.dart`, `lib/main.dart`, tests.

## Dependencies

TASK-030 also changes `settings_screen.dart`; this task starts after its
commit.

## Assigned Roles

- Advisor: main agent; owner decided the limit and the layout.
- Dev: main agent. QA Review: `qa-review` subagent. Docs: main agent.

## Acceptance Criteria

- [x] About matches the owner's layout in English and Khmer (widget test).
- [x] Cache tile shows a real size and a 500 MB bar; Clear Cache empties it (code and tests; phone check open).
- [x] Auto-clean above 500 MB on start (code and tests).
- [x] format, analyze, tests pass. Phone check open.

## Dev Results

- `CacheService` (`lib/data/storage/cache_service.dart`): `sizeBytes()`
  (recursive, files that vanish are skipped), `clear()` (everything inside
  the folder plus the in-memory image cache; files in use are kept and
  logged), `clearIfOverLimit()`; limit 500 MB (injectable for tests).
- `main.dart` runs `clearIfOverLimit()` in the background at start.
- `cacheServiceProvider`, `cacheSizeProvider`, `cacheLimitBytes` in the
  settings controller; `clearCache()` empties and measures again. The old
  `StorageService.clearAllCache()` (memory only) is removed.
- Settings: Clear Cache shows "86.4 MB of 500 MB" and a bar (red from 80 %);
  "Measuring..." while counting. `formatBytes` in `lib/core/format_bytes.dart`.
- About: DHMobile + version, Credits ("Player | ExoPlayer, VLC",
  "Contents | DonghuaCLI"), Development ("AMSCenter by AMSDev"), Privacy in
  the owner's line breaks. Unused keys `aboutPlayer`, `aboutContentSource`,
  `clearCacheDesc` removed. English and Khmer (Chinese in TASK-034).
- Tests: cache size, clear keeps the folder, over-limit only, missing
  folder, limit, `formatBytes`; About layout; the cache tile with a fake
  service (90 % → red, clear → 0 B). 252 passed.

## QA Results

Independent `qa-review` subagent, two rounds (one review with TASK-031/034).

Round 1: Changes Requested. Round 2: **Accepted** (code).

| Severity | Finding | Action |
| --- | --- | --- |
| High | H1: `Directory.systemTemp` is the code cache on Android (`PathUtils.getCacheDirectory` prefers `getCodeCacheDir()`), not `cache/` with the posters | Fixed: channel `dev.amscenter.donghua_player/storage` method `cacheDir` in `MainActivity.kt` returns `Context.getCacheDir()`; without an answer the service measures 0 and deletes nothing (never the PC's temp folder in tests); test |
| Medium | M2: Settings stays built in the IndexedStack, so the size was measured once, racing the auto-clean | Fixed: auto-clean in `MainScreen.initState`, then re-measure; opening the Settings tab re-measures |
| Low | L1: Khmer "Credits" was a word for a loan | Fixed: 'ការទទួលស្គាល់' |
| Low | L4: English reads "86.4 MB of 500 MB", not "/" | Kept ("of" reads better); Dev Results already said so |
| Low | L5: doc comment about files in use | Fixed |

Round 2 checks: analyze clean, 261 tests passed, format clean, release build OK (Kotlin change).

## Git Commit

- Commit Message: `feat(settings): new About and cache size bar [TASK-033]`
- Commit Hash:

## Notes and Limitations

- Committed together with TASK-034 and TASK-035 in one commit: their changes interleave in `app_strings.dart` (the Chinese table needs this task's keys and TASK-035's version line), `settings_screen.dart`, and the tests, so no split state would compile or pass. QA agreed.
- Open: check on the phone that the bar measures `cache/` (posters) and Clear Cache empties it.
