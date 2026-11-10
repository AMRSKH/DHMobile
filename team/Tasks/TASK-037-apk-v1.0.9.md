Author: AI Agent
Date: 2026-11-10
Task: TASK-037
Status: In Review

# TASK-037: Build and archive APK v1.0.9

## Objective

Release APKs with TASK-030 to TASK-036.

## Background

Owner `/task`, 2026-11-10: "update apk version". Same process as TASK-029
(v1.0.8).

Contents since v1.0.8: 2K/4K and "SubLang-Source quality" server labels
(TASK-030), faster start (TASK-031), Explore from every source (TASK-032),
new About and cache bar (TASK-033), Inter Khmer Looped and Chinese
(TASK-034), version label (TASK-035), Completed tab (TASK-036).

## Requirements

1. `version: 1.0.9+10`, `AppInfo` `1.0.9` / `10`, the version test follows.
2. Split release build from the committed TASK-036 plus the version change;
   copies with equal SHA256 in `apk/<abi>/`.
3. `apk/README.md` rows and provenance.
4. Install on the phone with `adb install -r` when it is connected.

## Dependencies

TASK-036 committed first.

## Acceptance Criteria

- [x] Version `1.0.9+10`; analyze clean, tests pass before the build.
- [x] Three APKs, SHA256 equal to the build output.
- [x] `aapt`: version name 1.0.9, codes 1010/2010/4010, `sdkVersion:'26'`.
- [x] README updated; older files untouched.
- [ ] Installed on the phone (if connected). Open: phone not connected.

## Dev Results

- Before the build: analyze clean, `00:20 +272: All tests passed!`.
- `flutter build apk --release --no-pub --split-per-abi`: armeabi-v7a 55.1MB, arm64-v8a 61.7MB, x86_64 69.0MB.
- Copies in `apk/<abi>/DHMobile-v1.0.9-<abi>.apk`, SHA256 equal to the build outputs (full values in `apk/README.md`).
- `aapt dump badging`: version name `1.0.9`, codes 1010 / 2010 / 4010, `sdkVersion:'26'`, one ABI each.
- v1.0.8 arm64-v8a keeps its README hash (`F6DA3156...`).

## QA Results

Self-check by the main agent (mechanical release task). The code in it was
reviewed in TASK-030 to TASK-036.

## Git Commit

- Commit Message: `chore(release): build APK v1.0.9 per ABI [TASK-037]`
- Commit Hash:

## Notes and Limitations

- Not installed and not tested on the phone: it is not connected. The phone checks of TASK-030 to TASK-036 are open with it.
- Debug signing key. Do not publish.
