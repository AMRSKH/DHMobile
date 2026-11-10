Author: AI Agent
Date: 2026-11-10
Task: TASK-023
Status: In Review

# TASK-023: Fixes from the device test of v1.0.5

## Objective

Test v1.0.5 on the owner's phone and fix what is broken, starting with the
issue the owner found: there is no search box.

## Background

Owner, 2026-11-10: "Now I connect Real Device. Test it, find issue now and
then apply fix. Issue I found is missed Search Box."

Device: Samsung SM-A546E, Android 17, arm64-v8a, 4 KB pages.

## Findings on the device

| ID | Severity | Finding | Cause |
| --- | --- | --- | --- |
| D1 | High | No way to search. | `SearchScreen` is not referenced anywhere. The owner baseline `3821d70` replaced the Search tab with Explore and added no other entry, so TASK-021's multi-source search was unreachable. |
| D2 | High | VLC never plays. Every load fails with `PlatformException(channel-error, Unable to establish connection on channel.)` and falls to ExoPlayer after 15 s. | Upstream bug solid-software/flutter_vlc_player#546: `flutter_vlc_player` 7.4.4 registers its Android Pigeon channels as `dev.flutter.pigeon.flutter_vlc_player_platform_interface.VlcPlayerApi.*`, but the published `flutter_vlc_player_platform_interface` 2.0.5 calls `dev.flutter.pigeon.VlcPlayerApi.*`. Checked in the release dex and both packages. Probably also why VLC was turned off on 2026-11-03. |
| D3 | High | After D2, VLC played but the picture was corrupt (blocks, mostly black), with `libvlc decoder: Timestamp conversion failed ... no reference clock` / `Could not convert timestamp 0 for mediacodec`. | libVLC MediaCodec hardware decoding on this phone. `HwAcc.decoding` gave a black picture. `HwAcc.disabled` (software decoding) gave a clean picture. |
| D4 | Low | The pushed Search page was titled "DHMobile". | Old title from when Search was a tab. |
| D5 | Info | Streams of the four new sources still do not play (Dailymotion master 403, Rumble 403). | Dailymotion now answers 403 to Python, curl, Dart, and the phone from this network, so it is not a Dart problem; cause not known (possibly rate limiting after testing, or a geo block). Not fixable in code here. |

## Fixes

1. D1: search button (`Icons.search`, tooltip "Search" / "ស្វែងរក") in the
   Explore app bar, opening `SearchScreen(autofocus: true)` as a page with a
   back button. Explore keeps its three tabs.
2. D2: `dependency_overrides` in `pubspec.yaml` pins
   `flutter_vlc_player_platform_interface` to the official repository at tag
   `7.4.4` (commit `988a7e67140786fb5510c96e4cb415dbfd837944`), whose
   channel names match. Owner approved the package change on 2026-11-10
   ("Git override"). `pubspec.lock`: only that package changes.
3. D3: `hwAcc: HwAcc.disabled` for VLC.
4. D4: Search page title is `S.search`.

## Scope

`pubspec.yaml`, `pubspec.lock`, `lib/features/explore/explore_screen.dart`,
`lib/features/search/search_screen.dart`, `lib/core/l10n/app_strings.dart`,
`lib/features/player/player_screen.dart` (one line), tests.

## Out of Scope

Dailymotion and Rumble access (D5), TLS bypass decision, APK build.

## Assigned Roles

- Advisor: main agent; owner chose the D2 fix.
- Dev: main agent.
- QA Review: `qa-review` subagent.
- Docs: main agent.

## Acceptance Criteria

- [x] Search can be opened from Explore; it searches all five sources (device: 13 merged results for "renegade immortal" from all five).
- [x] VLC plays on the device without the channel error (device, debug and release).
- [x] VLC picture is clean (device, release, OK.ru 720p, resume at 03:28 applied).
- [x] Manual server switch plays on VLC (device: 720p to 480p).
- [x] `dart format`, `flutter analyze --no-pub`, `flutter test --no-pub` pass (216).

## Device test log

| Check | Result |
| --- | --- |
| Explore, schedule, posters | OK |
| Search button opens Search, keyboard up, results with source badges | OK |
| AnimeXin episode on VLC (release, software decoding) | OK, CPU about 60 to 70 % of one core of eight |
| Resume from history ("Continue Ep 1 (03:28)") | OK |
| Controls, position, length on VLC | OK |
| Server menu and manual switch on VLC | OK |
| DonghuaWorld episode (Dailymotion) | No stream (D5) |

## QA Results

Independent `qa-review` subagent: **Accepted** (no Critical, High, or
Medium). analyze clean, 215 tests passed, format clean. Override checked:
full SHA of the official repo equals tag `7.4.4`; only that package changed
in the lock; all 47 Pigeon channel names and the codec match
`Messages.java` of 7.4.4; public Dart API compatible; no new imports or
network code. `HwAcc.disabled` maps to `setHWDecoderEnabled(false, false)`.

| Severity | Finding | Action |
| --- | --- | --- |
| Low | `searchControllerProvider` kept the last results when Search was opened again | Fixed: `NotifierProvider.autoDispose`, widget test (216 passed) |
| Low | `HwAcc.disabled` had no comment saying why | Fixed |
| Low | Software decoding for every device, judged on one phone | Accepted, see Notes |
| Info | Git dependency needs `git` and GitHub on a fresh `pub get`; lock shows version 2.0.5 for code that differs from pub.dev 2.0.5 | Accepted, explained in `pubspec.yaml` |

## Documentation Updates

AGENTS.md Technology stack: VLC software decoding and the pinned interface override.

## Git Commit

- Commit Message: `fix(app): add the search entry and make VLC play [TASK-023]`
- Commit Hash:

## Final Report

Search is back, as a button in the Explore app bar. VLC plays on the phone
for the first time: the interface override fixes the channel error and
software decoding fixes the corrupt picture. Device-checked: search across
five sources, VLC playback, resume, controls, manual server switch.

## Notes and Limitations

- Remove the override once a fixed interface is on pub.dev.
- Software decoding costs more battery than hardware decoding. ExoPlayer
  (Settings > Video Player) uses hardware decoding.
- The 16 KB page support of libVLC 3.6.3 was not tested (the phone has 4 KB
  pages).
