---
author: opencode
date: 2026-11-04
task: TASK-004
---

# TASK-004 — Development notes

## What was done

- Live-tested on SM A546E (<device-id>) via `flutter run`. Logs collected with a new `DLog` helper (`lib/core/debug_log.dart`) gated by `kDebugMode`.
- New findings and fixes:
  - `lib/data/providers/animexin_stream_provider.dart`: episode numbers are "NNN [MMM]" (e.g. `40 [248]`); `RegExp(r'[^0-9.]')` merged them into `40248`. Parse only the leading `^\d+` segment now.
  - `lib/data/providers/animexin_stream_provider.dart`: dedupe episode entries by URL (provider appended both `.bsx` nested and list rows), removing duplicate grid cards and stabilizing `Next Episode`.
  - `lib/data/providers/animexin_stream_provider.dart`: `search()` raw/resolved/ready + dedupe events logged for diagnostics.
- Player layout (`lib/features/player`): gesture overlay now wraps only the video surface; `PlayerControls`, the buffering indicator and the error dialog live in an *outer* `Stack`, so their buttons stay tappable while gestures reach the empty video area. `PlayerControls` scrim uses `IgnorePointer` so it never swallows taps.
- `PlayerControls` bottom row uses `Expanded` for the time label so the speed menu and Next Episode button stop being clipped off-screen.
- Existing watchdog (20 s), auto-hide-on-play, resume-at-position and source-skip behavior retained; one watchdog (src 0, 144p) fired and advanced to src 1 as designed.
- Episode number fix also makes `Next Episode` visibility correct (it was incorrectly hidden for the middle episodes).
- Navigation: tapping `Play` on `Swallowed Star Season 5` Episode 36244 worked; server-switch and pause/resume exercised.

## Known left as documented low issues
- Accessibility labels, stale episode counts, and dead upstream mirrors (EP 1 mirrors) remain low-priority.
- `badCertificateCallback` TLS bypass unchanged (needs host-allowlist decision).
- No new packages; native volume channel unchanged.

## Build
- Release APK: `build/app/outputs/flutter-apk/app-release.apk` (184.5 MB, 2026-11-04).
- Existing repo-root APKs left untouched.
