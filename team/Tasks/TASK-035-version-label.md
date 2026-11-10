Author: AI Agent
Date: 2026-11-10
Task: TASK-035
Status: In Review

# TASK-035: About version label without the build number

## Objective

Show "Version x.x.x" in About, without "(build x)".

## Background

Owner `/task`, 2026-11-10: "Update Version label in about i want "Version
x.x.x" no need (Build x)".

## Requirements

1. `S.versionLine` is "Version {version}" (English), "កំណែ {version}"
   (Khmer), "版本 {version}" (Chinese).
2. Settings no longer passes the build number. `AppInfo.buildNumber` stays:
   `test/app_info_test.dart` checks it against `pubspec.yaml`.

## Scope

`lib/core/l10n/app_strings.dart`, `lib/features/settings/settings_screen.dart`,
`test/settings_screen_test.dart`.

## Assigned Roles

- Advisor: skipped, small obvious change.
- Dev: main agent. QA Review: with the next QA round. Docs: none needed.

## Acceptance Criteria

- [x] About shows "Version 1.0.8" (no build) in every language (widget test, en/km/zh strings).
- [x] format, analyze, tests pass (256).

## QA Results

Reviewed in the second QA round of TASK-031/033/034 (independent `qa-review` subagent): the working tree with this change passed analyze, 261 tests, and the format check; no finding on it.

## Git Commit

- Commit Message: `fix(settings): show the version without the build number [TASK-035]`
- Commit Hash:

## Notes and Limitations

- Committed together with TASK-033 and TASK-034 (see TASK-033 Notes for why).
