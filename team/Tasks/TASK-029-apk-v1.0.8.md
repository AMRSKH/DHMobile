Author: AI Agent
Date: 2026-11-10
Task: TASK-029
Status: In Review

# TASK-029: Build and archive APK v1.0.8

## Objective

Release APKs with TASK-027 (ExoPlayer default) and TASK-028 (TLS checks,
minSdk 26), installed on the owner's phone.

## Background

Owner decision, 2026-11-10: "Yes, build v1.0.8 (Recommended)".

The build was made before the TASK-027 and TASK-028 commits, from the same
working tree, so it could serve as the device test of both tasks. Their
commits contain exactly the sources that were built (no change after the
build).

## Requirements

1. `version: 1.0.8+9`, `AppInfo` `1.0.8` / `9`, version test follows.
2. Split release build, copies with equal SHA256 in `apk/<abi>/`.
3. `apk/README.md` rows and provenance; note Android 8+.
4. `adb install -r` on the phone.

## Acceptance Criteria

- [x] Version `1.0.8+9`; analyze clean, 220 tests passed before the build.
- [x] Three APKs, SHA256 equal to the build output (218.8 s build).
- [x] `aapt`: version name 1.0.8, codes 1009/2009/4009, `sdkVersion:'26'`.
- [x] README updated; older files untouched (v1.0.7 arm64 hash unchanged).
- [x] Installed: `versionName=1.0.8`, `minSdk=26`; data kept.

## QA Results

Self-check by the main agent (mechanical release task). The device checks of
this build are in TASK-027 and TASK-028.

## Git Commit

- Commit Message: `chore(release): build APK v1.0.8 per ABI [TASK-029]`
- Commit Hash:

## Notes and Limitations

- Debug signing key. Do not publish.
- Needs Android 8 or newer.
