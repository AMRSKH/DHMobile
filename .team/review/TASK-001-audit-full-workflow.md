---
author: opencode
date: 2026-11-04
task: TASK-001
---

# Review — audit findings

## Fixed

| Severity | Issue | File | Status |
| --- | --- | --- | --- |
| Critical | Full-screen gesture layer sat above the controls, so play/pause, seek, speed, server, and next buttons could not be tapped. | `lib/features/player/widgets/gesture_overlay.dart` | Fixed; gesture layer moved below the player UI. |
| High | Player wrote progress straight to storage, so `historyProvider` never refreshed; history and continue-watching stayed stale. | `lib/features/player/player_screen.dart:149` | Fixed; syncs on pause, next episode, background, and exit. |
| High | Scraper failure generated 12 fake episodes with unplayable IDs. | `lib/data/providers/animexin_stream_provider.dart:131` | Fixed; returns an empty list and the UI shows the empty state. |
| Medium | Volume swipe only showed an indicator and changed nothing. | `lib/features/player/widgets/gesture_overlay.dart` | Fixed with an Android `AudioManager` method channel. |
| Medium | Detail screen scanned all history for every episode tile. | `lib/features/detail/detail_screen.dart:42` | Fixed with a per-build history map. |
| Medium | Playback continued in the background and kept the screen awake. | `lib/features/player/player_screen.dart:99` | Fixed with `WidgetsBindingObserver`. |
| Low | Settings showed version 1.0.0 while `pubspec.yaml` is 1.0.1. | `lib/features/settings/settings_screen.dart` | Fixed. |
| Low | Player listeners could index an empty source list or call `setState` after dispose. | `lib/features/player/player_screen.dart` | Fixed with guards and mounted checks. |

## Documented, not changed

| Severity | Issue | File | Reason |
| --- | --- | --- | --- |
| High | Global TLS validation is disabled for every HTTPS request. | `lib/main.dart:13` | Removing it may break third-party stream hosts. Needs a host allowlist decision. |
| Medium | Android allows cleartext traffic for all hosts. | `android/app/src/main/AndroidManifest.xml:10` | Some stream hosts may still use HTTP; needs a domain allowlist. |
| Medium | Preferred subtitle setting is saved but never applied to playback. | `lib/features/settings/settings_controller.dart:6` | Stream resolver does not expose subtitle tracks yet. |
| Medium | “Clear Cache” clears only the in-memory image cache, not the disk cache. | `lib/data/storage/storage_service.dart:190` | Needs a direct cache-manager dependency. |
| Low | VLC is effectively unused because `_useFallbackPlayer` starts as `true`. | `lib/features/player/player_screen.dart:48` | Intentional fallback preference; revisit after device testing. |
| Low | Seek slider sends a seek on every drag update. | `lib/features/player/widgets/player_controls.dart:185` | Works, but can be smoother with a local drag value. |
| Low | `README.md` is still Flutter boilerplate. | `README.md` | Documentation task, not a runtime issue. |

## Verdict

Approve with device verification still required. The critical control bug and stale-history bug are fixed, analyze and tests are green, and the debug APK builds.
