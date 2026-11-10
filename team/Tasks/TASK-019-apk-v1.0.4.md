Author: AI Agent
Date: 2026-11-10
Task: TASK-019
Status: In Review

# TASK-019: Build and archive APK v1.0.4

## Objective

Build the current app (with TASK-017 and TASK-018) as a new release APK set and add it to `apk/`.

## Background

Owner request, 2026-11-10: "Update apk file".

The newest APKs in `apk/` are v1.0.3 (`1.0.3+4`), built from TASK-015 (`9151a10`). TASK-017 and TASK-018 changed the Explore tabs after that build.

Owner answers to the main agent's questions:

- Bump the version to v1.0.4 and keep the v1.0.3 files.
- Split per ABI only (arm64-v8a, armeabi-v7a, x86_64), no universal APK.

## Requirements

1. `pubspec.yaml` `version: 1.0.4+5`, and `AppInfo.version = '1.0.4'`, `AppInfo.buildNumber = '5'` (AGENTS.md: they change together).
2. Tests that hold the version text follow the new version.
3. `flutter build apk --release --no-pub --split-per-abi` from the committed source plus the version change.
4. Copy the three files to `apk/<abi>/DHMobile-v1.0.4-<abi>.apk` (naming rule of `apk/README.md`), and check the SHA256 of each copy against its build output.
5. `apk/README.md`: add the three files with size, date, and SHA256, and a v1.0.4 provenance note.

## Scope

`pubspec.yaml` (version line only), `lib/core/app_info.dart`, the test with the version text (`test/settings_screen_test.dart`; `test/app_strings_test.dart` uses 1.0.3 only as a format sample and stays), `apk/README.md`, the APK files under `apk/` (not tracked by Git).

## Out of Scope

- Any dependency change, signing, or the universal APK.
- Removing or rebuilding older APKs.

## Assigned Roles

- Advisor: skipped. Mechanical release task, decisions taken by the owner.
- Dev: main agent (version edit, build, copy). Small mechanical change, no subagent.
- QA Review: `qa-review` subagent.
- Docs: main agent (`apk/README.md`).

## Implementation Plan

1. Version edits and tests.
2. Format, analyze, test.
3. Split release build.
4. Copy, hash check, README.
5. Install the arm64-v8a APK on the phone if it is connected.

## Dependencies

TASK-016 archive layout.

## Acceptance Criteria

- [x] `pubspec.yaml` is `1.0.4+5`, `AppInfo` matches, `app_info_test` passes.
- [x] Three v1.0.4 APKs exist under `apk/<abi>/`, each equal (SHA256) to its build output.
- [x] Each APK reports version name 1.0.4 and version code 5, and its ABI.
- [x] `apk/README.md` lists them correctly. The v1.0.3 files are unchanged.
- [x] `flutter analyze --no-pub` and `flutter test --no-pub` pass.

## Testing Requirements

Analyze, tests, release build, a check of the APK manifest values (`aapt` or `apkanalyzer` if available, else the build output metadata).

## Dev Results

By the main agent:

- `pubspec.yaml` `version: 1.0.4+5`, `lib/core/app_info.dart` `1.0.4` / `5`, `test/settings_screen_test.dart` expects `Version 1.0.4 (build 5)`.
- Checks before the build: format clean, `No issues found! (ran in 13.5s)`, `00:22 +182: All tests passed!`.
- `flutter build apk --release --no-pub --split-per-abi` (177.6 s): `app-armeabi-v7a-release.apk (53.9MB)`, `app-arm64-v8a-release.apk (60.7MB)`, `app-x86_64-release.apk (67.8MB)`.
- Copied to `apk/<abi>/DHMobile-v1.0.4-<abi>.apk`, each SHA256 equal to its build output.
- `aapt dump badging`: package `dhmobile.amscenter.dev`, label `DHMobile`, version name `1.0.4`, version codes 1005 (armeabi-v7a), 2005 (arm64-v8a), 4005 (x86_64), one native-code ABI each. The v1.0.3 files have 1004, 2004, 4004.
- `apk/README.md`: three rows, a v1.0.4 provenance section, and the compatibility and signing warnings extended to v1.0.4.

## QA Results

### Round 1: Accepted

By the `qa-review` subagent, without a rebuild. pubspec changed only the version line, `pubspec.lock` content unchanged. Analyze clean, `+182: All tests passed!`. SHA256 and size of the three new files equal the build outputs and the README; all 13 archived APKs match their README hashes, the v1.0.3 files are untouched. `aapt` values confirmed. The build outputs are newer than every source file, and the only source change after `4f1e8ee` is the version.

| ID | Severity | Finding | Decision |
| --- | --- | --- | --- |
| F1 | Low | Scope said two tests change, only one did | Scope corrected: `app_strings_test` is a format sample |
| F2 | Low | Three edited README lines were longer than 80 characters | Rewrapped |
| F3 | Low | The README Size column says "MB" for MiB values (from TASK-016) | Left: the note under the table explains it |

## Documentation Updates

`apk/README.md` (main agent), as above. No other document names the app version.

## Git Commit

- Commit Message: chore(release): build APK v1.0.4 per ABI [TASK-019]
- Commit Hash:

## Final Report

v1.0.4 (`1.0.4+5`) is built and archived per ABI in `apk/`, with the underline tabs of TASK-017 and TASK-018. For the SM-A546E use `apk/arm64-v8a/DHMobile-v1.0.4-arm64-v8a.apk`. It upgrades an installed v1.0.3.

## Notes and Limitations

- Not installed on the phone: it was disconnected.
- The APKs are not tracked by Git. The commit holds the version change and `apk/README.md`.
- Debug signing key, as for v1.0.3. Do not publish.
