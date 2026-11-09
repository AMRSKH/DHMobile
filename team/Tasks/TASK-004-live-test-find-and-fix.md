---
author: opencode
date: 2026-11-04
task: TASK-004
---

# Live test on the physical device, find issues, and fix them

## Status

- [x] Planned
- [x] In progress
- [x] QA
- [x] Review
- [x] Done

## Goal

Every main user flow runs on the Galaxy A54 5G without crashing, freezing, or showing wrong data, and the real issues found during that live run are fixed and retested on the device.

## Scope

**In scope**

- Run the app live on `SM A546E` (`<device-id>`) with `flutter run`.
- Walk these flows on the device:
  - cold start, home/search list, poster loading
  - search a title, empty result, network failure
  - open detail, episode list, resume banner
  - play an episode, server list, buffering, seek, speed, next episode
  - gestures: tap, double-tap seek, brightness, volume
  - pause, background, return, exit
  - favorites, history, continue watching
  - settings changes and persistence
- Record every issue with severity, file, and line.
- Fix high and medium issues that are in app code.
- Retest each fix on the device.
- Re-run `dart format`, `flutter analyze`, and `flutter test`.
- Build a fresh APK after fixes.

**Out of scope**

- New features, redesigns, or new packages.
- TLS bypass and cleartext allowlist changes (blocked in TASK-001).
- Subtitle playback and disk cache clearing (blocked in TASK-001).
- Upstream site changes that need a scraper rewrite.
- Emulator or Android Studio testing.

## Acceptance criteria

- [ ] All listed flows are run on the physical device and their result is recorded.
- [ ] Each issue found has a severity, file, and line reference.
- [ ] High and medium issues in app code are fixed or documented as blocked with a reason.
- [ ] Every fix is retested on the device.
- [ ] No new crash or ANR appears during the retest.
- [ ] `flutter analyze` passes with no issues.
- [ ] `flutter test` passes.
- [ ] Changed Dart files are formatted.
- [ ] A new APK is built and its path is reported.
- [ ] Results are written to `.team/qa/` and `.team/review/`.

## Plan

1. Confirm the device is connected and authorized (`adb devices -l`, `flutter devices`).
2. Start a live session and keep the debug console visible.
3. Walk the in-scope flows in order and record pass/fail plus screenshots or log lines.
4. Triage findings: severity, root cause, file, line.
5. Fix the high and medium app-code issues in small changes.
6. Hot Reload to check, then Hot Restart for a clean check.
7. Re-run the affected flows on the device.
8. Run `dart format`, `flutter analyze`, and `flutter test`.
9. Build a release APK and report the path.
10. Write the QA and review notes with the remaining known issues.

## Risks

- **Scraper depends on the live AnimeXin site.** Mitigation: separate app bugs from upstream or network failures and label them clearly.
- **Device-only bugs are hard to reproduce.** Mitigation: capture logcat while reproducing and note the exact steps.
- **Fixing while testing can hide regressions.** Mitigation: retest each flow after Hot Restart, not only after Hot Reload.
- **Slow debug builds on this machine.** Mitigation: batch fixes, then rebuild once.
- **Scope creep into blocked TASK-001 items.** Mitigation: keep TLS, subtitles, and cache clearing out and list them as known issues.
- **A fix may break another flow.** Mitigation: run the full test suite and a quick device pass after each fix.

## Notes

- Flutter is not on PATH. Use `D:\DevTools\flutter\bin\flutter.bat`.
- Device serial: `<device-id>`.
- Live testing setup is documented in `FLUTTER_LIVE_TESTING.md`.
- Related: `.team/tasks/TASK-001-audit-full-workflow.md`, `.team/tasks/TASK-002-app-icon-and-working-streams.md`.
