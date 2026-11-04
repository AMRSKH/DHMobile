---
author: opencode
date: 2026-11-04
task: TASK-002
---

# New app icon and only working stream sources

## Status

- [x] Planned
- [x] In progress
- [x] QA
- [x] Review
- [ ] Done

## Goal

The app ships with a new launcher icon, and when a user plays an episode the server picker lists only stream sources that can actually play, so no dead or broken mirror is offered.

## Scope

**In scope**

- Replace the Android launcher icon (all mipmap densities) with the image the user provides.
- Add an adaptive icon (foreground + background) so it looks correct on Android 8+.
- Update the icon shown in the app if one is hardcoded.
- Filter resolved stream sources before they reach the player:
  - Keep only direct playable media (`.m3u8`, `.mp4`, `.mkv`, `.webm`) or URLs that pass a reachability check.
  - Drop resolver output that is still an HTML embed page.
  - De-duplicate identical URLs.
- Show only the filtered list in the player server selector, and auto-play the first working source.
- Keep a clear error state when no working source exists.

**Out of scope**

- New scraping hosts or new providers.
- Subtitle track support.
- Redesign of the player UI beyond the server list.
- Changing the TLS or cleartext configuration.

## Acceptance criteria

- [ ] Launcher icon is replaced on all densities and looks correct in the app drawer and recents.
- [ ] Adaptive icon renders without clipping on Android 8+.
- [x] `flutter build apk --release` succeeds after the icon change.
- [x] Playing an episode lists only sources that return playable media.
- [x] A source that is an HTML embed page or returns an error is not listed.
- [x] Duplicate URLs appear once.
- [x] If every source fails, the player shows a readable error instead of an endless buffering spinner.
- [x] `flutter analyze` passes.
- [x] `flutter test` passes, with a test covering the source filter.

## Plan

1. Wait for the user's icon image, then generate mipmap sizes and adaptive icon layers.
2. Update `android/app/src/main/AndroidManifest.xml` icon references if needed.
3. Add a filtering step in `lib/data/providers/stream_resolver.dart` (or a small helper next to it) that:
   - rejects non-media URLs,
   - probes candidate URLs with a short HEAD/GET timeout,
   - returns a de-duplicated list.
4. Apply the filter in `AnimeXinStreamProvider.streams()` before returning.
5. Confirm `lib/features/player/player_screen.dart` selects index 0 of the filtered list and shows the error state when the list is empty.
6. Add tests for the filter and the empty-list path.
7. Run `dart format`, `flutter analyze`, `flutter test`, and build a release APK.

## Risks

- **Probing adds startup delay.** Mitigation: short timeout (3-4 s) and probe candidates in parallel with `Future.wait`.
- **Some working hosts reject HEAD.** Mitigation: fall back to a ranged GET, or keep URLs that match a known media extension without probing.
- **Hosts may block the app's user agent.** Mitigation: reuse the existing `kDefaultUserAgent` and referer headers.
- **Icon clipping on adaptive icons.** Mitigation: keep the artwork inside the safe zone and test with a mask preview.
- **Filtering may remove the only source.** Mitigation: keep the empty-state message and let the user retry or pick another server later.

## Notes

- Icon artwork provided by the user: `DHPlayer.png` (512x512, transparent, red and black).
- Icon background chosen: white `#FFFFFF`.
- Related files: `lib/data/providers/stream_source_filter.dart`, `lib/data/providers/animexin_stream_provider.dart`, `lib/features/player/player_screen.dart`.
- Dev, QA, and review notes go in `.team/dev/`, `.team/qa/`, `.team/review/` with the same task ID.

## Result

- Icon: all 5 mipmap densities regenerated, adaptive icon added (`mipmap-anydpi-v26/ic_launcher.xml`, `values/ic_launcher_background.xml`).
- Stream filter: `StreamSourceFilter` de-duplicates, probes with HEAD (4 s), falls back to a ranged GET when HEAD is rejected, and drops HTML or error responses.
- Tests: 4 new tests in `test/stream_source_filter_test.dart`; `flutter test` 12 passed.
- `flutter analyze`: no issues.
- APK: `DonghuaPlayer-v1.0.1-icon-streams.apk` (release, debug-signed).
- Still needs a visual check of the icon on a device.
