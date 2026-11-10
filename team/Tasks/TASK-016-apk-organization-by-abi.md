Author: AI Agent
Date: 2026-11-10
Task: TASK-016
Status: In Review

# TASK-016: Organize APK builds by chip architecture and rename to DHMobile

## Objective

Group every APK built so far, and the new v1.0.3+4 release builds, into folders by chip architecture (ABI), and rename the files from `DonghuaPlayer` to `DHMobile`, the short form of "Donghua Mobile".

## Background

Owner request, 2026-11-10:

> Now TASK-015 Puased let Organize APK Version from Start to now again by Chip Archecture type.

Owner answers to the two questions of the main agent:

- Build the current tree (v1.0.3+4, the paused TASK-015 work) split per ABI, and add those files too.
- Rename the files to `DHMobile`, not `DonghuaPlayer`.

State before the task:

- TASK-015 was `In Review` and uncommitted when this task started; the owner paused it, so this task does not touch that code. The TASK-015 session then resumed and committed it as `9151a10` during this task, so the v1.0.3 build comes from that commit's source.
- Seven APKs sit in the repo root, all ignored by Git (`*.apk` in `.gitignore`): `DonghuaPlayer-v1.0.0.apk`, `DonghuaPlayer-v1.0.1.apk`, `DonghuaPlayer-v1.0.1-auditfix.apk`, `DonghuaPlayer-v1.0.1-icon-streams.apk` (multi-ABI), and `DonghuaPlayer-v1.0.1-arm64.apk`, `DonghuaPlayer-v1.0.1-armv7.apk`, `DonghuaPlayer-v1.0.1-x86_64.apk` (split).
- `pubspec.yaml` is `1.0.3+4`. The last split build in `build/` is from 2026-11-04 (v1.0.1 split).
- The app label in `AndroidManifest.xml` is `DHMobile` (TASK-015).

## Requirements

1. Create an `apk/` folder with one subfolder per ABI: `universal`, `arm64-v8a`, `armeabi-v7a`, `x86_64`.
2. Move every existing root APK into its ABI folder, renamed to the `DHMobile` prefix, keeping version and variant in the name.
3. Build v1.0.3+4 with `flutter build apk --release --split-per-abi` from the current tree and copy the three per-ABI files into their folders.
4. Leave the repo root free of APK files.
5. Add `apk/README.md` that explains the folder layout and the naming rule (the APKs themselves stay untracked).
6. Record that TASK-015 is paused, without changing its scope or code.

## Scope

- New `apk/` folder and its files, moved from the repo root and copied from `build/app/outputs/flutter-apk/`.
- New `apk/README.md`.
- Release build of the current tree (no source change expected).
- `team/Tasks/TASK-015-splash-explore-skeleton-language.md` status note.
- `team/Tasks/TASK-016-apk-organization-by-abi.md` (this file).

## Out of Scope

- Any change to `lib/`, `android/`, `test/`, `pubspec.yaml`, or `pubspec.lock`.
- TASK-015 QA, fixes, device check, and commit.
- Rebuilding the old v1.0.0 and v1.0.1 files; they are moved as they are.
- Signing, publishing, or pushing.

## Assigned Roles

- Advisor: `advisor` subagent.
- Dev: `dev` subagent.
- QA Review: `qa-review` subagent.
- Docs: `docs` subagent.

## Implementation Plan

1. Advisor: check the folder and naming scheme, the build command, and the risks of building a paused tree.
2. Dev: create the folders, move and rename the seven root APKs, run the split release build, copy the new APKs, write `apk/README.md`, and record the file list and sizes.
3. QA Review: check the tree, the file names, the ABI of each APK (`apkanalyzer`/`unzip` check of `lib/<abi>/`), and that the checks still pass.
4. Docs: update `apk/README.md` if needed and any other affected document.
5. Final validation: format, analyze, test, build, `git status` and `git diff`.
6. Commit the task file and `apk/README.md`.

## Advisor Recommendation

By the `advisor` subagent, 2026-11-10. Nothing was run or built. Condensed by the main agent.

1. Naming: `apk/<abi>/DHMobile-<version>[-<variant>]-<abi>.apk`, ABI always the last token. Final names:

   | Old (repo root) | New path |
   | --- | --- |
   | `DonghuaPlayer-v1.0.0.apk` | `apk/universal/DHMobile-v1.0.0-universal.apk` |
   | `DonghuaPlayer-v1.0.1.apk` | `apk/universal/DHMobile-v1.0.1-universal.apk` |
   | `DonghuaPlayer-v1.0.1-auditfix.apk` | `apk/universal/DHMobile-v1.0.1-auditfix-universal.apk` |
   | `DonghuaPlayer-v1.0.1-icon-streams.apk` | `apk/universal/DHMobile-v1.0.1-icon-streams-universal.apk` |
   | `DonghuaPlayer-v1.0.1-arm64.apk` | `apk/arm64-v8a/DHMobile-v1.0.1-arm64-v8a.apk` |
   | `DonghuaPlayer-v1.0.1-armv7.apk` | `apk/armeabi-v7a/DHMobile-v1.0.1-armeabi-v7a.apk` |
   | `DonghuaPlayer-v1.0.1-x86_64.apk` | `apk/x86_64/DHMobile-v1.0.1-x86_64.apk` |
   | new build | `apk/arm64-v8a/DHMobile-v1.0.3-arm64-v8a.apk` |
   | new build | `apk/armeabi-v7a/DHMobile-v1.0.3-armeabi-v7a.apk` |
   | new build | `apk/x86_64/DHMobile-v1.0.3-x86_64.apk` |

2. Copy, verify the SHA256, then delete the root original. The APKs are gitignored, so Git is no backup.
3. Build: `flutter build apk --release --no-pub --split-per-abi`, after `flutter analyze --no-pub` and `flutter test --no-pub` pass. Stop if they fail. No `--target-platform`. Do not reuse the old 2026-11-04 splits in `build/`.
4. ABI check: read the `lib/<abi>/` entries of each APK with `System.IO.Compression.ZipFile`; one ABI per split, three for universal.
5. `apk/README.md` is tracked; `*.apk` stays ignored at any depth, so no `.gitignore` change.
6. Commit only the task file and `apk/README.md`. Leave the untracked TASK-015 file unstaged.

Facts the advisor confirmed: the old APKs use application id `dev.amscenter.donghua_player`; the current tree uses `dhmobile.amscenter.dev` and debug signing, so the new APKs do not upgrade the old app. The README must say so.

## Dependencies

- Flutter SDK at `D:\DevTools\flutter\bin\flutter.bat` (not on PATH).
- The Gradle and Android SDK cache for a release build.

## Acceptance Criteria

- [x] `apk/universal/`, `apk/arm64-v8a/`, `apk/armeabi-v7a/`, and `apk/x86_64/` exist.
- [x] Every APK built so far is inside the folder that matches its ABI, named `DHMobile-...`.
- [x] `DHMobile-v1.0.3-arm64-v8a.apk`, `DHMobile-v1.0.3-armeabi-v7a.apk`, and `DHMobile-v1.0.3-x86_64.apk` exist and come from a successful release build of the current tree.
- [x] No APK file is left in the repo root.
- [x] `apk/README.md` states the layout and naming rule.
- [x] TASK-015 is recorded as paused.
- [x] `flutter analyze --no-pub` passes.
- [x] `flutter test --no-pub` passes.
- [ ] Task file and `apk/README.md` are committed locally.

## Testing Requirements

- `flutter build apk --release --split-per-abi` succeeds.
- Each new APK contains native libraries for exactly its ABI.
- Existing APK sizes are recorded before and after the move; no file is lost.
- `flutter analyze --no-pub` and `flutter test --no-pub` still pass.

## QA Results

Independent `qa-review` subagent, 2026-11-10. Verdict: **Changes Requested** on the first pass, one Major finding: the `apk/README.md` provenance note still said the v1.0.3 APKs were "not reproducible from any commit", because TASK-015 was committed as `9151a10` during the review. Fixed in the README and in this file.

Verified by QA:

| Check | Result |
| --- | --- |
| `git status` | Only the expected `apk/`, this task file, and the owner's TASK-015 edit |
| ABI scan of all 10 APKs (`ZipFile`, `lib/<abi>/`) | Pass: one ABI per split, three per universal |
| README sizes, dates, SHA256 vs `Get-FileHash` | Pass, all 10 match |
| v1.0.3 copies vs `build/app/outputs/flutter-apk/` | Pass, 3/3 identical |
| `aapt2` package ids | Old APKs `dev.amscenter.donghua_player`, v1.0.3 `dhmobile.amscenter.dev`, label `DHMobile`, versionName 1.0.3 |
| `flutter analyze --no-pub` | `No issues found!` |
| `flutter test --no-pub` | All 153 tests passed |
| Secrets in `apk/README.md` and this file | None |

Minor findings recorded, not changed: the pre-move sizes are only in the Dev log, since the originals are deleted; `build/app/outputs/flutter-apk/app-release.apk` is an old universal v1.0.3 build that is not archived; and the v1.0.3 manifest still names `dev.amscenter.donghua_player.MainActivity` (TASK-015 code, out of scope here).

## Documentation Updates

Updated by the `docs` subagent, 2026-11-10, against the tree and the QA results:

- `AGENTS.md`: the repository layout now lists `apk/`; the Release build and
  Split build command rows state the `build/app/outputs/flutter-apk/` output;
  the "APKs in the repo root" sentence now points at `apk/<abi>/` and
  `apk/README.md`.
- `FLUTTER_LIVE_TESTING.md`: the APK build section says the raw output stays in
  `build\app\outputs\flutter-apk\` and that kept builds are copied to
  `apk\<abi>\` under the `DHMobile-...` names.
- `apk/README.md`: the v1.0.3 provenance note now states directly that the three
  files are the build of `9151a10`, and that no tracked source file changed
  after that commit. Folder list, names, sizes, dates, and all ten SHA256 values
  were rechecked against the files on disk and match.
- No change to `README.md`, the role files in `team/`, or any task record from
  TASK-001 to TASK-015.

## Final Validation

Run by the main agent on 2026-11-10, after the Docs stage:

| Check | Command | Result |
| --- | --- | --- |
| Format | `dart format` on changed Dart files | Not applicable: no Dart file changed |
| Lint | `flutter analyze --no-pub` | `No issues found!` (13.5 s) |
| Test | `flutter test --no-pub` | `All tests passed!` (153 tests, 33 s) |
| Build | `flutter build apk --release --no-pub --split-per-abi` | Built 3 APKs, 428.9 s (Dev stage). Not rerun after the doc-only edits |
| Tree | `git status`, `git diff` | Only this task's files, plus the owner's TASK-015 completion edit; no secrets, no `.apk` staged |

## Git Commit

- Commit Message:
- Commit Hash:

## Final Report

## Notes and Limitations
