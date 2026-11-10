Author: AI Agent
Date: 2026-11-10
Task: TASK-020
Status: Completed

# TASK-020: VLC as the main player, ExoPlayer as fallback

## Objective

Make libVLC (`flutter_vlc_player`) the player that plays every stream first,
as the project was designed, with `video_player` (ExoPlayer) only as a
fallback.

## Background

Owner, 2026-11-10: the project is built on DonghuaCLI ideas and "VLC is the
backbone of this project".

Since commit `d98afc4` (2026-11-03) `_useFallbackPlayer` starts as `true` in
`player_screen.dart`, so VLC is never used, while `libvlc.so` still takes
42.8 MB of the 60.7 MB arm64-v8a APK. TASK-001 noted this as "revisit after
device testing". No reason for the switch is recorded beyond the comment
"preferred for reliable native Android hardware decode".

The flag was also sticky: after one VLC failure, the whole player screen
stayed on ExoPlayer for every later source and episode.

Checked before the change (2026-11-10): a Dailymotion HLS master, variant, and
segment all load with only `User-Agent` and `Referer` (no `Cookie`), so VLC,
which can only send those two headers, can play the Dailymotion sources.

## Requirements

1. Every new load (first load, failover to another source, source picked by
   hand, next episode, retry) starts on VLC.
2. When VLC fails on a source (error, init exception, or no playback before
   its watchdog), the same source is loaded again on ExoPlayer, at the same
   position. Only when ExoPlayer also fails does the player fail over to the
   next source.
3. A Settings choice "Video player": VLC (default) or ExoPlayer, stored in
   the settings box, for devices where VLC misbehaves.
4. VLC calls that throw on an uninitialized controller (`pause`, `play`,
   `seekTo`, `setPlaybackSpeed`) are not made before it is initialized.
5. The chosen speed is applied to a new VLC load once it plays.
6. A VLC load that starts while the app is in the background is paused.
7. Settings About shows the engine that is actually used.
8. English and Khmer text for every new label.

## Scope

- `lib/domain/models/player_engine.dart` (new)
- `lib/features/player/player_screen.dart`
- `lib/features/settings/settings_controller.dart`, `settings_screen.dart`
- `lib/data/storage/storage_service.dart`
- `lib/core/app_info.dart`, `lib/core/l10n/app_strings.dart`
- Tests in `test/`

## Out of Scope

- Removing `video_player` or `flutter_vlc_player`, package changes.
- Subtitle tracks in VLC.
- Live testing on a device (none attached on 2026-11-10).

## Assigned Roles

- Advisor: main agent
- Dev: main agent
- QA Review: `qa-review` subagent
- Docs: main agent

## Implementation Plan

1. `PlayerEngine` enum (`vlc`, `exo`) with a stored code and
   `fallbackEngine()` (VLC falls back to ExoPlayer, ExoPlayer to nothing).
2. Replace `_useFallbackPlayer` with a per-load `_engine`.
3. Setting, storage key `player_engine`, Settings tile.
4. Guards for the VLC calls, speed on start, background pause.
5. Tests: engine enum and fallback, settings round trip, settings screen tile.

## Dependencies

None.

## Acceptance Criteria

- [x] A new load starts on the engine from Settings (VLC by default).
- [x] VLC failure retries the same source on ExoPlayer before failover.
- [x] Settings shows and stores the choice, in English and Khmer.
- [x] No VLC call on an uninitialized controller.
- [x] `dart format`, `flutter analyze --no-pub`, `flutter test --no-pub` pass.

## Testing Requirements

Unit and widget tests. The player screen itself needs a device; it is not
covered by widget tests (platform views).

## QA Results

Independent `qa-review` subagent, two rounds.

Round 1: Changes Requested.

| ID | Severity | Finding | Fix |
| --- | --- | --- | --- |
| H1 | High | `VlcPlayer` had no key: a new controller reused the old platform view and never initialized (manual source switch, reload on resume) | `key: ObjectKey(_vlcController)` |
| M1 | Medium | The Android plugin reports VLC buffering as "not buffering", so the watchdog never fired for a stalled VLC load | `_loadHasPlayed`; for VLC the watchdog and the spinner use it |
| M2 | Medium | A VLC "ended" in the middle (dead HLS input) jumped to the next episode | `isNearEnd()`; an early end is an engine failure. Checked against the larger of the last and the reported position |
| M3 | Medium | The package's own lifecycle observer played again on return from the background | `allowBackgroundPlayback: true` |
| L2 | Low | VLC teardown, play, and pause Futures unhandled; empty `catch` | `_vlcCall()` logs sync throws and Future errors |
| L1, L3, L4 | Low | VLC setup errors only reach the watchdog; resume can be lost if the length is 0 at the first frame; a dead source can now cost 15 s + 20 s | Accepted, see Notes |
| L5 | Low | Fallback logic has no unit test | Partly: `isNearEnd` tests |

Round 2: Accepted. analyze clean, 209 tests passed, format clean.

## Documentation Updates

- `AppInfo.playerEngine` removed: the engine is a setting now. Settings About shows the chain from `PlayerEngine.chain`.
- AGENTS.md already names `flutter_vlc_player` with `video_player` as fallback, which is now true.

## Git Commit

- Commit Message: `feat(player): make VLC the main player with ExoPlayer fallback [TASK-020]`
- Commit Hash: fa22927

## Final Report

Every load starts on the Settings engine (VLC by default). VLC failure (error, setup exception, early end, or 15 s without a first frame) reloads the same source on ExoPlayer at the same position; ExoPlayer failure fails over to the next source. New Settings tile "Video Player" (VLC / ExoPlayer), key `player_engine`, English and Khmer text.

Checks: `dart format` clean, `flutter analyze --no-pub` no issues, `flutter test --no-pub` 208 passed (QA run: 209 incl. a temporary live test).

## Notes and Limitations

- Not verified on a device (none attached): VLC playback, the VLC to ExoPlayer timing, end-of-episode position, lifecycle.
- If VLC misbehaves on a phone, Settings > Video Player > ExoPlayer restores the old behaviour.
- VLC sends only `User-Agent` and `Referer`. The Dailymotion `Cookie` is not needed (checked 2026-11-10).
- `_startPositionPolling` keeps an older `catch (_) {}` (predates this task).
