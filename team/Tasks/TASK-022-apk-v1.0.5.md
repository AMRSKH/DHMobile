Author: AI Agent
Date: 2026-11-10
Task: TASK-022
Status: Completed

# TASK-022: Build and archive APK v1.0.5

## Objective

Build the app with TASK-020 (VLC as main player) and TASK-021 (five sources)
as a new release APK set in `apk/`, so the owner can test both on a phone.

## Background

Owner, 2026-11-10: "Yes, build v1.0.5", after the main agent offered an
arm64-v8a build for phone testing. Same process as TASK-019 (v1.0.4).

The TLS item that was called "TASK-022" in chat earlier was never recorded as
a task file. It waits for an owner decision and gets the next free number
when it starts.

## Requirements

1. `pubspec.yaml` `version: 1.0.5+6`, `AppInfo.version = '1.0.5'`,
   `AppInfo.buildNumber = '6'`; the test with the version text follows.
2. `flutter build apk --release --no-pub --split-per-abi` from `d068b9d` plus
   the version change.
3. Copy to `apk/<abi>/DHMobile-v1.0.5-<abi>.apk`, SHA256 equal to the build
   output.
4. `apk/README.md`: three rows and a v1.0.5 provenance note.

## Scope

`pubspec.yaml` (version line), `lib/core/app_info.dart`,
`test/settings_screen_test.dart`, `apk/README.md`, APK files (not tracked).

## Out of Scope

- Signing with a release key, the universal APK, dependency changes.
- Removing or rebuilding older APKs.

## Assigned Roles

- Advisor: skipped, mechanical release task.
- Dev: main agent.
- QA Review: main agent self-check (not independent), see QA Results.
- Docs: main agent (`apk/README.md`).

## Acceptance Criteria

- [x] Version `1.0.5+6` in pubspec and `AppInfo`, tests pass.
- [x] Three v1.0.5 APKs under `apk/<abi>/`, SHA256 equal to the build output.
- [x] `aapt` reports version name 1.0.5, version codes 1006/2006/4006.
- [x] `apk/README.md` lists them. Older files unchanged.

## Dev Results

- Version edits as required. Before the build: format clean, `No issues found! (ran in 13.1s)`, `00:20 +214: All tests passed!`.
- `flutter build apk --release --no-pub --split-per-abi` (146.4 s): armeabi-v7a 54.0MB, arm64-v8a 60.7MB, x86_64 67.9MB.
- Copied to `apk/<abi>/DHMobile-v1.0.5-<abi>.apk`; each SHA256 equals its build output (arm64-v8a `44E570AD...`, armeabi-v7a `F1FC6F38...`, x86_64 `6D3DA010...`, full values in `apk/README.md`).
- `aapt dump badging`: `dhmobile.amscenter.dev`, label `DHMobile`, version name `1.0.5`, codes 1006 / 2006 / 4006, one native ABI each.

## QA Results

Self-check by the main agent, not independent (mechanical release task, as in
TASK-019 the decisions were the owner's). The v1.0.4 arm64-v8a file still has
its README hash (`BC1BF1ED...`), so the older files were not touched.

## Documentation Updates

`apk/README.md`: three rows, a v1.0.5 provenance section, warnings extended to v1.0.5.

## Git Commit

- Commit Message: `chore(release): build APK v1.0.5 per ABI [TASK-022]`
- Commit Hash: d8dcb5e

## Final Report

v1.0.5 (`1.0.5+6`) is archived per ABI. For a phone on Android 7+ with a 64-bit CPU use `apk/arm64-v8a/DHMobile-v1.0.5-arm64-v8a.apk`. It upgrades an installed v1.0.4.

## Notes and Limitations

- Not installed: no device attached.
- Built with a formatting-only working-tree change in `stream_resolver.dart` (not committed, no code change).
- Debug signing key. Do not publish.
- Streams of the four new sources did not play from the build machine (Rumble 403, Dailymotion 403 from Dart). To be checked on the phone.
