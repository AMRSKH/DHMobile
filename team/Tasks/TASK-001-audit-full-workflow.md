---
author: opencode
date: 2026-11-04
task: TASK-001
---

# Audit full app workflow and fix issues

## Status

- [x] Planned
- [x] In progress
- [x] QA
- [x] Review
- [ ] Done

## Goal

Every main user flow works end to end, and the issues found during the audit are fixed or documented with a clear reason.

## Scope

**In scope**

- Startup: storage init, providers, theme, routing.
- Browse and search: home list, search query, empty and error states.
- Detail: show info, episode list, stream resolution.
- Playback: stream start, controls, gestures, resume/history.
- Library and settings: favorites, history, saved preferences.
- Data layer: AnimeXin scraper, stream resolver, Hive storage.
- Error handling, loading states, and network failures.
- Performance: startup time, list scrolling, image loading, rebuilds, and playback start.

**Out of scope**

- New features or redesigns.
- iOS-specific behavior.
- Publishing to stores.
- Rewriting the scraper if the upstream site changes.

## Acceptance criteria

- [x] Each flow above is walked through and its result is recorded.
- [x] Every found issue has a severity, file, and line reference.
- [x] High-severity issues are fixed or documented as blocked.
- [ ] A performance baseline is recorded for startup, scrolling, and playback start. (Blocked: no device/emulator; build and test timings are recorded.)
- [x] Obvious performance problems are fixed or logged with evidence.
- [x] `flutter analyze` passes with no new issues.
- [x] `flutter test` passes.
- [x] Changed Dart files are formatted.
- [x] Audit results are written to `.team/review/`.

## Plan

1. Read `AGENTS.md` and map the app flows from `lib/main.dart`.
2. Audit startup, storage, and provider wiring.
3. Audit home, search, and detail screens.
4. Audit player, controls, and gesture behavior.
5. Audit library, settings, and persistence.
6. Audit the scraper and stream resolver for failures and edge cases.
7. Profile startup, list scrolling, image loading, and playback start.
8. Rank issues by severity and fix the high-impact ones in small changes.
9. Run `dart format`, `flutter analyze`, and `flutter test`.
10. Write findings, performance notes, and fixes to `.team/review/` and `.team/dev/`.

## Risks

- The scraper depends on `animexin.dev`; network or markup changes can block verification.
- Playback needs a real device or emulator; some bugs may not reproduce in tests.
- The audit can grow without limits; fix only high-impact issues and log the rest.
- `lib/main.dart` disables TLS validation; changing it may break playback and needs a separate decision.

## Notes

- Performance is in scope: startup, scrolling, image loading, rebuilds, and playback start.
- Device/emulator verification is still pending; no device was available for the run.
- Related notes: `.team/dev/TASK-001-audit-full-workflow.md`, `.team/qa/TASK-001-audit-full-workflow.md`, `.team/review/TASK-001-audit-full-workflow.md`
