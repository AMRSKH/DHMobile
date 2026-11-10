Author: AI Agent
Date: 2026-11-10
Task: TASK-026
Status: In Review

# TASK-026: Build and archive APK v1.0.7

## Objective

Build the app with TASK-025 (re-resolve sources when every server fails) as a
new release APK set in `apk/`, and install it on the owner's phone.

## Background

Owner, 2026-11-10: "Yes, build v1.0.7". Same process as TASK-024.

## Requirements

1. `pubspec.yaml` `version: 1.0.7+8`, `AppInfo.version = '1.0.7'`,
   `AppInfo.buildNumber = '8'`; the test with the version text follows.
2. `flutter build apk --release --no-pub --split-per-abi` from `1ddf4a4`
   (TASK-025) plus the version change.
3. Copy to `apk/<abi>/DHMobile-v1.0.7-<abi>.apk`, SHA256 equal to the build
   output.
4. `apk/README.md`: three rows and a v1.0.7 provenance note.
5. Install the arm64-v8a APK with `adb install -r` (keeps app data).

## Scope

`pubspec.yaml` (version line), `lib/core/app_info.dart`,
`test/settings_screen_test.dart`, `apk/README.md`, APK files (not tracked).

## Out of Scope

Signing with a release key, the universal APK, dependency changes, older APKs.

## Assigned Roles

- Advisor: skipped, mechanical release task.
- Dev: main agent.
- QA Review: main agent self-check (not independent).
- Docs: main agent (`apk/README.md`).

## Acceptance Criteria

- [x] Version `1.0.7+8` in pubspec and `AppInfo`, tests pass.
- [x] Three v1.0.7 APKs under `apk/<abi>/`, SHA256 equal to the build output.
- [x] `aapt` reports version name 1.0.7, version codes 1008/2008/4008.
- [x] `apk/README.md` lists them. Older files unchanged.
- [x] Installed on the phone, version 1.0.7.

## Dev Results

- Before the build: format clean, `No issues found!`, `00:23 +220: All tests passed!`.
- `flutter build apk --release --no-pub --split-per-abi` (177.0 s): armeabi-v7a 54.8MB, arm64-v8a 61.5MB, x86_64 68.7MB.
- Copied to `apk/<abi>/DHMobile-v1.0.7-<abi>.apk`; each SHA256 equals its build output (full values in `apk/README.md`).
- `aapt dump badging`: version name `1.0.7`, codes 1008 / 2008 / 4008, one native ABI each.
- `adb install -r` on the SM-A546E: version 1.0.7.

## QA Results

Self-check by the main agent, not independent. The v1.0.6 arm64-v8a file
keeps its README hash (`0F47ACFC...`). Smoke test on the phone: Explore with
the search button, "Continue" from the saved history (data kept by
`adb install -r`), VLC playback with a clean picture, no channel error.

## Documentation Updates

`apk/README.md`: three rows, v1.0.7 provenance, warnings extended to v1.0.7.

## Git Commit

- Commit Message: `chore(release): build APK v1.0.7 per ABI [TASK-026]`
- Commit Hash:

## Final Report

v1.0.7 (`1.0.7+8`) is archived per ABI and installed on the owner's phone.

## Notes and Limitations

- Debug signing key. Do not publish.
- Known open items: VLC grey or smeared frames at times (cause unknown), Dailymotion and Rumble 403, TLS bypass decision.
