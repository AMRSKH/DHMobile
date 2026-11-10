Author: AI Agent
Date: 2026-11-10
Task: TASK-014
Status: In Review

# TASK-014: Live Test on Phone, Find Issues, and Fix

## Objective

Run the app on the owner's Galaxy A54, find real issues in the main user flows, and fix the ones that are in app code.

## Background

The working tree holds a large amount of uncommitted app work from before the harness reset (splash, explore, player controls, scraper changes). TASK-004 ran a similar pass on 2026-11-04. This pass tests the app as it is in the working tree today.

## Requirements

- Test on the physical device, not an emulator.
- Record every issue with severity and location.
- Fix issues in app code, and retest each fix on the device.

## Scope

Main flows: cold start, home, explore, search, detail, playback, gestures, library, settings.

## Out of Scope

- New features, redesigns, and new packages.
- The TLS bypass in `lib/main.dart` (known issue, flagged in `AGENTS.md`).
- Upstream site changes that would need a scraper rewrite.

## Assigned Roles

- Advisor: `advisor` subagent
- Dev: `dev` subagent, device retest by the main agent
- QA Review: `qa-review` subagent
- Docs: `docs` subagent

## Implementation Plan

1. Confirm the device and the installed build.
2. Run the app live and walk the flows, capturing logs and screenshots.
3. Triage findings.
4. Fix, then retest on the device.
5. Format, analyze, test, and build.

## Dependencies

A connected, unlocked device and the live AnimeXin site.

## Acceptance Criteria

- [x] Each in-scope flow was run on the device and its result recorded. Search is not reachable from the UI (F2).
- [x] Each issue has a severity and a file reference.
- [ ] Fixed issues were retested on the device. Done for F1, F3 to F10, F12 to F14, and R2 to R4. Open: R1 exhaustion and the L1, L2, L4 edits, see Notes.
- [x] `flutter analyze --no-pub` passes.
- [x] `flutter test --no-pub` passes.

## Testing Requirements

Device run with log capture, plus the standard checks.

## Live Test Results

Device: Galaxy A54 (SM-A546E), Android 17, debug build of the working tree, installed over the existing app with data kept. Date: 2026-11-10.

| Flow | Result |
| --- | --- |
| Cold start and splash | Pass, also after a force-stop relaunch |
| Explore (default weekday) | Pass: 7 cards from a pool of 21, posters load |
| Explore weekday switch and refresh | Pass, see F1 for titles |
| Search | Not reachable from the UI, see F2 |
| Detail | Pass: 11 episodes, Continue button, progress bars. No synopsis or genres for scraped shows |
| Playback start | Pass: 12 sources kept, video renders, controls auto-hide |
| Pause and play | Pause works. Resume tap missed while buffering, see F4 |
| Seek buttons and double-tap seek | Pass |
| Brightness and volume drag | Pass with controls hidden, see F8 |
| Speed menu | Opens, selection lost after controls auto-hide, see F5 |
| Source switch | Pass, see F7 for the menu layout |
| Next episode | Pass, source choice resets, see F6 |
| Background and return | Pauses and saves. Stays paused with controls hidden, see F9 |
| Back from player | Orientation restored. See F8 and F10 |
| Favorite toggle (Detail and Library) | Pass |
| Library History | List renders, play resumes at the saved position, remove works. See F10, F11, F12. "Clear All" not run |
| Library Favorites | Pass: grid, heart toggle, empty state |
| Settings | Pass: quality dialog, value persists across restart. Subtitle dialog opens, see F3. Clear actions not run |

## Findings

| ID | Severity | Location | Issue |
| --- | --- | --- | --- |
| F1 | Medium | `lib/data/providers/animexin_stream_provider.dart` `_scrapeWeekdayTrending` | Explore items are homepage episode posts. The show title carries the episode suffix ("... Episode 11 Indonesia, English Sub") in Explore, Detail, Player, and Library. `show.id` is an episode post URL, so favorites and history keyed by it will not match next week's post. |
| F2 | Low, needs the owner's decision | `lib/features/home/main_screen.dart`, `lib/features/search/search_screen.dart` | `SearchScreen` exists but nothing in the UI opens it. |
| F3 | Medium | `lib/features/player/player_screen.dart` `_findInitialSourceIndex`, `lib/features/settings/` | "Preferred Subtitle Language" is stored but never used. With English selected, the default source was a "Hardsub Indonesia" one although a "Hardsub English" source existed. |
| F4 | Low | `lib/features/player/widgets/player_controls.dart` | The buffering spinner replaces the play/pause button, so the user cannot pause or resume while buffering. |
| F5 | Medium | `lib/features/player/player_screen.dart` `_startHideControlsTimer`, `player_controls.dart` popup menus | Controls auto-hide after 4 s while the speed or source menu is open. The menu button is removed from the tree and the selection is dropped silently. |
| F6 | Medium | `lib/features/player/player_screen.dart` `_handleNextEpisode` | Next episode resets the source to the default instead of keeping the server and quality the user picked. |
| F7 | Medium | `lib/features/player/widgets/player_controls.dart` source menu | RenderFlex overflow on long source labels, and the quality is printed twice ("... 144p (144p)"). |
| F8 | Medium | `lib/features/player/widgets/gesture_overlay.dart`, `player_screen.dart` `dispose` | The app brightness override set by the brightness gesture stays active after leaving the player, until the process restarts. |
| F9 | Low | `lib/features/player/player_screen.dart` `didChangeAppLifecycleState` | After returning from the background the video is paused with the controls hidden, so the screen looks frozen. |
| F10 | Medium | `lib/features/player/player_screen.dart` `dispose`, `_saveProgress` | After leaving the player, Library History and the Detail "Continue" button show stale progress until the app restarts. The periodic save writes storage without updating `historyProvider`, and the `ref` based save in `dispose()` fails inside an empty `catch`. The exit position itself is not saved, only the last 5 s tick. |
| F11 | Low | `lib/features/library/library_screen.dart` `_HistoryCard` | Play from History passes a one-episode list, so there is no next-episode button and no auto-advance. |
| F12 | Low | `lib/features/library/library_screen.dart` `_HistoryCard` | The label reads "Episode 2 • Episode 2" when the episode title is "Episode N". |
| F13 | Medium | `lib/features/player/player_screen.dart` `_initializeStream`, `onSourceChanged` | Switching the source in the middle of an episode restarts it at 0. Found by the advisor from code. |

Observations, not planned for this task:

- Settings About text is hardcoded ("Version 1.0.3 (Release)", "libVLC") while the default player is `video_player`.
- "Clear Cache" clears only the in-memory image cache.
- Explore weekday lists are a seeded shuffle of homepage posts, not a real schedule.
- The seek slider seeks on every drag update.
- Vertical gestures do nothing while the controls are shown.

## Advisor Recommendation

From the `advisor` subagent (read-only, working tree). It did not run tests or open the site.

| ID | Decision | Approach |
| --- | --- | --- |
| F1 | Fix, title only | Pure `cleanShowTitle()` used in `_scrapeWeekdayTrending`. Do not normalize `show.id`: the homepage only links episode posts, and existing Hive favorites and history are keyed by the current id with no migration. |
| F3 | Fix | Pure `pickInitialSourceIndex(sources, quality, subtitle)`. Language tier first (match, neutral, other language), then quality (exact, else nearest height). "None" skips the language step. |
| F4 | Fix | Keep the play/pause button mounted, draw the spinner as a ring over it inside `IgnorePointer`. |
| F5 | Fix | `onMenuOpened` and `onMenuClosed` callbacks. The player holds `_menuOpen`, and `_startHideControlsTimer` returns early while it is set. Offstage was rejected: the menu would float over hidden controls. |
| F6 | Fix | Remember the source the user picked (`_userSource`, not set on failover) and match it by server and quality in the next episode's list. |
| F7 | Fix | `sourceLabel()` adds the quality only when the server label lacks it. `Flexible` text with ellipsis, wider menu. |
| F8 | Fix | `ScreenBrightness.instance.resetApplicationScreenBrightness()` from `_PlayerScreenState.dispose()`. Not in `GestureOverlay.dispose()`, which runs on every episode change. |
| F9 | Fix | On `resumed`, show the controls when not playing. No auto-resume. |
| F10 | Fix first | `ref.read` throws in `State.dispose()` in flutter_riverpod 3.3.2 (`_assertNotDisposed`). Capture the history notifier and the storage service in `initState`, use them in `_saveProgress`, and log errors instead of swallowing them. |
| F11 | Defer | The full list needs a network scrape (`showEpisodesProvider`), a loading state, and a fallback. Workaround: open the card, then Continue in Detail. |
| F12 | Fix | `historyEpisodeLabel()` drops the title when it only repeats "Episode N". |
| F13 | Fix, verify on device | Found by the advisor from code: switching source mid-episode likely restarts at 0, since `_initializeStream` zeroes the position. Carry the current position into `_pendingResumeMs` on manual switch and on failover. |

Order: F10, F8, F5, then F3 with F6 and F7, F4, F9, F13, F12, F1. F2 waits for the owner's decision.

## Dev Results

Implemented by the `dev` subagent: F1, F3, F4, F5, F6, F7, F8, F9, F10, F12, F13. Not implemented: F2 (owner decision), F11 (deferred).

Files changed:

- `lib/features/player/player_screen.dart`: notifier and storage captured in `initState` and used by `_saveProgress` (F10), brightness reset in `dispose` (F8), `_menuOpen` guard on the hide timer (F5), source choice through `pickInitialSourceIndex` and `stickySourceIndex` (F3, F6), controls shown on resume when paused (F9), `_carryPositionToNextLoad` on manual switch and failover (F13).
- `lib/features/player/widgets/player_controls.dart`: menu open and close callbacks (F5), `sourceLabel`, ellipsis, and wider menu (F7), play/pause button kept mounted under the buffering ring (F4).
- `lib/features/library/library_screen.dart`: `historyEpisodeLabel` (F12).
- `lib/data/providers/animexin_stream_provider.dart`: `cleanShowTitle` in `_scrapeWeekdayTrending` (F1).

Files created: `lib/features/player/source_selection.dart`, `test/source_selection_test.dart`, `test/show_title_test.dart`, `test/history_episode_label_test.dart`, `test/player_controls_test.dart`.

Deviations from the advisor plan:

- `_handleNextEpisode` disposes the players before loading the next episode, so the old listener cannot write the old position onto the new episode. Side effect: the old audio stops at once on Next.
- With subtitle "None" and no matching quality, the nearest height is picked. The old code fell back to the first source.
- `cleanShowTitle` tests live in a new file, because `test/stream_provider_test.dart` is unformatted owner work.
- `dart format` reformatted all of `library_screen.dart` and `player_screen.dart`, so their diffs carry whitespace noise.

Checks reported by Dev: `dart format` clean on the 9 files, `flutter analyze --no-pub` "No issues found!", `flutter test --no-pub` "+40: All tests passed!".

Main agent: `flutter build apk --debug --no-pub` passed ("Built build\app\outputs\flutter-apk\app-debug.apk").

### Device retest, round 1

Fixed debug build installed over the existing app (`adb install -r`, data kept), 2026-11-10. Observed by the main agent through screenshots and `[DH]` logs.

| Fix | Result |
| --- | --- |
| F1 | Pass: Explore and Detail show the show title without the episode suffix |
| F3 | Pass: English + 720p started on "Hardsub English Ok.ru 720p" (source 10 of 12), English subtitles on screen. Indonesian and None not tried in this round |
| F4 | Partial: the ring is drawn around the button and the icon stays visible. A tap while buffering after a seek did not pause (2 attempts). See R3 |
| F5 | Pass: speed menu open for 7 s, controls stayed, 1.25x applied, controls hid afterwards. Source menu open for 6 s, same |
| F6 | Pass: Next kept "Hardsub English Ok.ru 480p" on episode 2 |
| F7 | Pass: no overflow, quality printed once, check mark on the current source |
| F8 | Pass: window brightness override present after the drag, gone after leaving the player |
| F9 | Pass: Home and return shows the paused video with the controls and the play icon |
| F10 | Pass (back arrow): Detail "Continue" and Library History show the exit position at once, no `player.saveProgress` error |
| F12 | Pass: History shows "Episode 2" once |
| F13 | Pass: switched source at about 01:30, playback continued from there |

## QA Results

### Round 1

Independent `qa-review` subagent (no edit tools), on the round 1 working tree. Verdict: **Accepted**, no Critical or High findings.

Its checks: `dart format --output=none --set-exit-if-changed` on the 9 files "Formatted 9 files (0 changed)", `flutter analyze --no-pub` "No issues found!", `flutter test --no-pub` "+40: All tests passed!". It compared against a baseline rebuilt outside the repo: only Dev's 4 tracked files and 5 new files differ, `pubspec.yaml`, `android/`, and the old tests are untouched. Mutation checks on F3, F4, F5, and F7 failed the tests as expected, removing the menu width constraint did not.

| ID | Severity | Finding | Follow-up |
| --- | --- | --- | --- |
| M1 | Medium | Failover is forward-only, and F3 and F6 now start near the end of the list (English + 720p is 10 of 12). One fallback at most, and the watchdog does nothing at the last source | Round 2, R1 |
| M2 | Medium | No automated test for the `PlayerScreen` wiring (F5 gate, F6, F8, F9, F10, F13) | Round 2 adds pure functions with tests for failover and the carried position. The rest stays device-tested only |
| L1 | Low | Language tier treats another hardsub language as neutral, and matches "indo" as a substring | Not changed, see Notes |
| L2 | Low | Quality "Auto" picks the first source, which is 144p on this site. Older behaviour, now pinned by a test | Not changed, see Notes |
| L3 | Low | Leaving while a new source loads skips the exit save, since the position is 0 | Round 2, R5 |
| L4 | Low | History sync runs in `dispose()`, after the pop transition | Not changed, see Notes |
| L5 | Low | `cleanShowTitle` leaves trailing separators and cuts real titles that contain " Episode N" | Round 2 trims separators. The second part stays, see Notes |
| L6 | Low | `historyEpisodeLabel` does not match "Episode 02" with number 2 | Round 2, R5 |
| L7 | Low | Duplicate `_carryPositionToNextLoad()` in `_vlcListener` (dead path) | Not changed |
| L8 | Low | `_menuOpen` can stay true when the controls unmount under an open menu | Round 2, R5 |
| L9 | Low | F13 has no row in Findings, F2 has no severity | Fixed in this file |
| L10 | Low | Menu width constraint is not covered by a test | Not changed |

### Round 2

Independent `qa-review` subagent (no edit tools), on the round 2 working tree including the F14 fix. Verdict: **Accepted**, no Critical or High findings. The round 2 changes are described in the section "Round 2" below.

Its checks: `dart format --output=none --set-exit-if-changed` on the 9 task files "Formatted 9 files (0 changed)", `flutter analyze --no-pub` "No issues found!", `flutter test --no-pub` "+59: All tests passed!". Scope against its own baseline: only the 4 tracked task files differ, plus `source_selection.dart` and the 4 new tests. `pubspec.yaml`, `pubspec.lock`, and `android/` are unchanged.

It also ran a probe widget test of the real `PlayerScreen` against a fake `VideoPlayerPlatform`, in a copy outside the repo (26 scenarios), and 10 mutants of the pure functions (all killed). Confirmed there, not on a device: the failover order 10, 9, 8, 11, 7, 6, 4, 3, 2, 5, 1, 0 and then the error with "Retry Stream", Retry back at source 10 with the carried position, the stale load guard, pause and play while buffering, the speed on a new controller, no play call for a load that finishes in the background, and the deferred failover with a reload on return.

| ID | Severity | Finding | Follow-up |
| --- | --- | --- | --- |
| M1 | Medium | Still no automated test of the `PlayerScreen` wiring (round 1 M2). The probe shows it is practical with a fake platform | Not done in this task, see Notes |
| L1 | Low | A speed of 1.0x picked while buffering was not re-applied, playback stayed at the older speed | Fixed by the main agent |
| L2 | Low | `_isPlaying` could become true when the app left during the `play()` call of a load | Fixed by the main agent |
| L3 | Low | The reload after a deferred failover always plays, also when the user had paused before leaving | Not changed, see Notes |
| L4 | Low | The 20 s watchdog counted time spent in the background | Fixed by the main agent: re-armed on return |
| L5 | Low | `_wantPlaying` does not follow a pause made by the platform (end of video, audio focus). A buffering phase after that shows the wrong icon once | Not changed, see Notes |
| L6 | Low | The exhaustion panel is drawn under the controls, the play button covers part of the message. "Retry Stream" stays reachable | Not changed, see Notes |
| L7 | Low | The exhaustion loop in `test/source_selection_test.dart` had no bound and could hang | Fixed by the main agent |
| L8 | Low | `_pendingResumeMs` is cleared before the seek is known to work (by reading only) | Not changed, see Notes |
| L9 | Low | "Retry Stream" reuses the resolved source list. If the addresses expire, Retry keeps failing until the episode is reopened (not verified) | Not changed, see Notes |

Re-check by the same subagent after the L1, L2, L4, and L7 edits: all four fixed, no regression, verdict stays **Accepted**. Evidence from its probe: the 1.0x speed call now reaches the platform, leaving during the `play()` call shows the play icon and the controls, 4 s in the foreground plus 17 s away no longer fails over, and the two mutants that hung the suite now fail with "index N picked twice". Its 21 probe scenarios gave the same results as before apart from the fixes. Checks again: format "Formatted 9 files (0 changed)", analyze "No issues found!", tests "+59: All tests passed!". Not verified by QA: anything on a device.

## Round 2

Source: QA round 1 and the device retest. Brief written by the main agent, implementation by the `dev` subagent.

| ID | Item |
| --- | --- |
| R1 | Failover picks the best source that has not failed yet (same language, nearest quality), over the whole list. When every source failed, the player shows an error with "Retry Stream" instead of a spinner |
| R2 | Stale load guard: a load that was replaced (fast source switch, Next, failover) no longer triggers a failover or overwrites the state of the new load |
| R3 | Pause while buffering. `video_player` 2.11.1 reports `isPlaying` false while ExoPlayer buffers, so the tap called `play()`. The toggle, the icon, and the background pause now use what the user asked for while buffering |
| R4 | Playback speed is applied to a new controller (source switch, failover, Next), and again when playback starts after a speed change made while buffering |
| R5 | L3, L5 (separators), L6, L8, and the carried-position rule as a pure function |

### Dev results, round 2

Implemented by the `dev` subagent: R1 to R5.

- `lib/features/player/player_screen.dart`: `_failedSources` and `_failover()` over the whole list with an exhaustion error (R1), `_loadGeneration` guard in `_initializeStream` (R2), `_wantPlaying` and `_effectivePlaying` for the toggle, the icon, and the background pause (R3), speed set on each new controller and again when playback starts (R4), exit save and `_menuOpen` reset (R5).
- `lib/features/player/source_selection.dart`: `pickFailoverSourceIndex`, `carriedResumeMs`.
- `lib/features/library/library_screen.dart`: `historyEpisodeLabel` compares the number, so "Episode 02" matches 2.
- `lib/data/providers/animexin_stream_provider.dart`: `cleanShowTitle` trims trailing separators.
- Tests extended: `test/source_selection_test.dart`, `test/show_title_test.dart`, `test/history_episode_label_test.dart`.

Deviations reported by Dev: the old message "Playback failed. Try switching servers." is gone, the stale guard runs before the error log, the speed is set before the listener is attached.

Edits by the main agent, after the Dev hand-back:

| Edit | Reason |
| --- | --- |
| "Retry Stream" clears the failed set and starts at the sticky or preferred source | Dev note: after exhaustion the index sat on the last, worst source |
| A load sets `_wantPlaying = true` at its start, and plays only if that is still true when it is ready | Dev note: a load that finished while the app was in the background started its audio there |
| `_inBackground` and `_reloadOnResume`: a failure while the app is in the background does not fail over, the same source is loaded again on return | F14, found in the round 2 device retest |
| Speed re-applied also for 1.0x, `_isPlaying` after `play()` follows the intent, watchdog re-armed on return | QA round 2: L1, L2, L4 |
| Bounded exhaustion loop in `test/source_selection_test.dart` | QA round 2: L7 |

New finding in round 2:

| ID | Severity | Location | Issue |
| --- | --- | --- | --- |
| F14 | Medium | `lib/features/player/player_screen.dart` `_failover` | A load that runs while the app is in the background fails with an ExoPlayer "Source error", and each failure moved to the next source (observed: 8 to 10 to 9 within 12 s). A longer stay would mark every source as failed and show the "No server could play this episode" error although the sources work. Fixed, see the table above. |

Checks by the main agent on the final tree: `dart format` on the changed files "0 changed", `flutter analyze --no-pub` "No issues found!", `flutter test --no-pub` "+59: All tests passed!", `flutter build apk --debug --no-pub` "Built build\app\outputs\flutter-apk\app-debug.apk".

### Device retest, round 2

Debug builds installed over the existing app (`adb install -r`, data kept), 2026-11-10. Observed by the main agent through screenshots and `[DH]` logs.

| Item | Result |
| --- | --- |
| R3 pause while buffering (after a slider seek, 720p) | Pass: log `pause=true playing=false buffering=true want=true`, the video stayed paused with the play icon, a second tap resumed |
| R2 two quick source switches (480p, then 360p) | Pass: two `player.init`, one `player.ready` for the last source, no failover, no error |
| R4 speed after a source switch (1.5x, to 240p) | Pass: 44 s of video in 29.3 s, 1.50x. Position carried |
| R4 speed after Next | Pass: 45 s of video in 29.6 s, 1.52x. Label 1.5x |
| Sticky source across episodes | Pass: the 240p source picked by hand was kept on the next episode, although its list had 12 sources instead of 6 |
| Auto-advance at the end of an episode | Pass: episode 1 to 2 of 108, no exception |
| End of an episode opened from History | No crash. Stops at the end with the play icon, no advance, see Notes (F11) |
| F14 before the fix | Fail: failover 8 to 10 to 9 while the app was in the background |
| F14 after the fix | Pass: source switch, Home, 34 s away. Log: one `ERROR player.init`, then `player.failover deferred src=8`, nothing else. On return `player.failover reload src=8`, `player.ready src=8`, playback continued at the carried position (09:25) |
| Background while playing, after the F14 fix | Pass: paused on leaving, play icon and controls on return, play tap resumed |
| Leave the player with the back arrow | Pass: portrait restored |
| R1 exhaustion error and "Retry Stream" | Not observed on the device: no natural case where every source fails. Covered by the QA probe test only |
| L1, L2, L4 edits (last build) | Not retested on the device: the phone was disconnected when the last build was ready. Covered by format, analyze, tests, and the QA re-check only |

## Documentation Updates

Checked by the `docs` subagent: no document affected, no files changed. `README.md`, `AGENTS.md`, and the `team/` documents state nothing about the player source selection, failover, resume, history label, or title cleanup that this task changed. The `AGENTS.md` structure listing still matches: `source_selection.dart` is inside `lib/features/player/`, the new tests are inside `test/`. No package, build, or command changed.

Its observations about older owner work, not changed in this task:

- `AGENTS.md` names `flutter_vlc_player` as the player with `video_player` as fallback. In the working tree `_useFallbackPlayer` starts as `true`, so `video_player` is the only player in use.
- `README.md` is still the Flutter template text.
- `AGENTS.md` says screens do not call storage directly and forbids empty `catch` blocks outside scraper code. `player_screen.dart` calls `StorageService` for the periodic save and keeps three `catch (_) {}` around the VLC controller. Both look older than this task, not confirmed by diff.

## Git Commit

Two local commits on `dev`, as the owner decided. Not pushed.

The task's changes sat in files that also held the owner's older uncommitted app work. That work went into its own commit first:

- Baseline: `3821d70` feat(app): add explore, splash and debug log, rework player (owner baseline). It is the owner's work from before this task, rebuilt from the diff saved at the start of the task. The only edit is `dart format` on nine files, which the pre-commit hook requires. It includes `FLUTTER_LIVE_TESTING.md`, `android/app/proguard-rules.pro`, and `.vscode/settings.json`. Checks on that tree: analyze clean, 12 tests pass, debug APK builds.

The task commit holds the four files this task changed, `source_selection.dart`, the four new tests, this record, and the TASK-013 record edit (hash and status).

- Commit Message: fix(player): fix source choice, failover, resume and titles from live test [TASK-014]
- Commit Hash:

## Final Report

The app was tested live on a Samsung SM-A546E. The test found 14 issues (F1 to F14). QA round 1 and the device retest led to five round 2 items (R1 to R5).

- Fixed: F1, F3 to F10, F12 to F14, and R1 to R5.
- Not changed: F2 (needs the owner's decision) and F11 (deferred).
- QA: two rounds by the `qa-review` subagent, both Accepted. The Lows L1, L2, L4, and L7 from round 2 were fixed and re-checked by the same subagent.
- Checks on the final tree: `dart format` no change, `flutter analyze --no-pub` no issues, `flutter test --no-pub` 59 tests pass, debug APK builds.
- Device retest: done for every fix except the R1 exhaustion error and the L1, L2, and L4 edits. The phone was disconnected when the last build was ready, so the phone still runs the build before those three edits.

## Notes and Limitations

Open, waiting for the owner:

- F2: `SearchScreen` is not reachable from the UI. Not changed.
- Quality "Auto" picks the first source, which is 144p on this site (round 1 L2). Product decision.

Deferred:

- F11: playback from Library History passes one episode, so there is no Next button and no auto-advance. `show.id` in history is an episode post URL, so the episode list needs a scrape.
- No automated test of the `PlayerScreen` wiring (QA M1). The QA probe tests are outside the repo and were not added.
- QA round 2 L3, L5, L6, L8, L9, and round 1 L1, L4, L7, L10.

Not verified on the device:

- The exhaustion error and "Retry Stream" (R1): no natural case where every source fails.
- The L1, L2, and L4 edits: the phone was disconnected when the last build was ready.
- The subtitle settings "Indonesian" and "None".

Known behaviour:

- `show.id` from Explore is still an episode post URL. Favorites and history keyed by it will not match next week's post.
- Hive entries saved before the F1 fix keep the long title.
- `cleanShowTitle` cuts a real title that contains " Episode N", and trims a real trailing hyphen.
- A finished episode is stored with position 0, so History shows "00:00 / duration" for it.
- A source switch while paused starts playback.
- The watchdog covers the start of a load, not an endless rebuffer in the middle of playback.
- Failed sources add up within one episode. They are cleared by a manual switch, "Retry Stream", or a new list.
- `player.init` writes the stream URL to the debug log (debug builds only).
- 720p at 1.5x rebuffers often on the test network.

Test side effects on the device: Library History holds entries from this test ("Golden Curse" episodes 1 and 2, "Spiritual Realm Walker" episode 1, "Tales of Herding Gods" episodes 1 to 3). Not removed.
