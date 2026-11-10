Author: AI Agent
Date: 2026-11-10
Task: TASK-024
Status: In Review

# TASK-024: Build and archive APK v1.0.6

## Objective

Build the app with TASK-023 (search entry, VLC channel fix, software
decoding) as a new release APK set in `apk/`, and install it on the
owner's phone.

## Background

Owner, 2026-11-10: "Yes, build v1.0.6". Same process as TASK-022.

## Requirements

1. `pubspec.yaml` `version: 1.0.6+7`, `AppInfo.version = '1.0.6'`,
   `AppInfo.buildNumber = '7'`; the test with the version text follows.
2. `flutter build apk --release --no-pub --split-per-abi` from `02ed2bd` (TASK-023) plus
   the version change.
3. Copy to `apk/<abi>/DHMobile-v1.0.6-<abi>.apk`, SHA256 equal to the build
   output.
4. `apk/README.md`: three rows and a v1.0.6 provenance note.

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

- [x] Version `1.0.6+7` in pubspec and `AppInfo`, tests pass.
- [x] Three v1.0.6 APKs under `apk/<abi>/`, SHA256 equal to the build output.
- [x] `aapt` reports version name 1.0.6, version codes 1007/2007/4007.
- [x] `apk/README.md` lists them. Older files unchanged.

## Dev Results

- Before the build: format clean, `No issues found!`, `00:21 +216: All tests passed!`.
- `flutter build apk --release --no-pub --split-per-abi` (207.3 s): armeabi-v7a 54.8MB, arm64-v8a 61.5MB, x86_64 68.7MB.
- Copied to `apk/<abi>/DHMobile-v1.0.6-<abi>.apk`; each SHA256 equals its build output (full values in `apk/README.md`).
- `aapt dump badging`: version name `1.0.6`, codes 1007 / 2007 / 4007, one native ABI each.
- Installed `DHMobile-v1.0.6-arm64-v8a.apk` on the SM-A546E (`adb install -r`, version 1.0.6 confirmed).

## QA Results

Self-check by the main agent, not independent (mechanical release task). The
v1.0.5 arm64-v8a file keeps its README hash (`44E570AD...`).

Smoke test of v1.0.6 on the phone: search button, Explore (one load failed
during a short network drop, Retry worked), VLC playback with a clean picture
from the episode start. Two problems seen during testing, see Notes.

## Documentation Updates

`apk/README.md`: three rows, v1.0.6 provenance, warnings extended to v1.0.6.

## Git Commit

- Commit Message: `chore(release): build APK v1.0.6 per ABI [TASK-024]`
- Commit Hash:

## Final Report

v1.0.6 (`1.0.6+7`) is archived per ABI and installed on the owner's phone.

## Notes and Limitations

- Debug signing key. Do not publish.
- Testing with `flutter run` reinstalled the app and cleared its data on the
  phone (history, favorites, language). `adb install -r` of an APK keeps it.
- VLC still showed grey or smeared frames at times (with
  `Timestamp conversion failed ... no reference clock`, now from FFmpeg),
  mostly after a resume. Turning off frame skipping did not clearly help and
  was not kept. Cause not known.
- Stream URLs of OK.ru carry `srcIp`, and the public IP of the owner's
  network changed between runs (carrier-grade NAT). A URL resolved on one IP
  and played on another can be refused, which fits the random 403s. A retry
  that resolves the sources again would help; not done here.

