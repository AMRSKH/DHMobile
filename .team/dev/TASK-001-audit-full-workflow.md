---
author: opencode
date: 2026-11-04
task: TASK-001
---

# Dev notes — audit fixes

## Changes

- `lib/features/player/widgets/gesture_overlay.dart`
  - Moved the full-screen gesture layer below the player UI so buttons and sliders receive taps.
  - Added a real volume channel call instead of a visual-only volume indicator.
- `android/app/src/main/kotlin/dev/amscenter/donghua_player/MainActivity.kt`
  - Added a `dev.amscenter.donghua_player/volume` method channel backed by `AudioManager`.
- `lib/features/player/player_screen.dart`
  - Progress now syncs `historyProvider` on pause, next episode, background, and exit.
  - Periodic saves still write directly to storage to avoid rebuilding the library every 5 seconds.
  - Added app lifecycle handling, empty-source guards, mounted checks, and an end-of-video guard.
  - Reduced VLC position polling from 500 ms to 1 second.
- `lib/data/providers/animexin_stream_provider.dart`
  - Removed the fake 12-episode fallback; scraping failures now return an empty list.
- `lib/features/detail/detail_screen.dart`
  - Builds an episode-id history map once instead of scanning history for every episode tile.
- `lib/features/settings/settings_screen.dart`
  - Version label now matches `pubspec.yaml` (`1.0.1`).

## Tests added

- `test/gesture_overlay_test.dart` — controls must receive taps above the gesture layer.
- `test/history_controller_test.dart` — history provider refreshes after a progress save.

## Notes

- `dart format` reformatted the touched files with the current Dart style, so diffs are larger than the logical changes.
- No package was added. The volume fix uses native Android code.
