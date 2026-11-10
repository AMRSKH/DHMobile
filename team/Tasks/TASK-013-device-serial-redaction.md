Author: AI Agent
Date: 2026-11-10
Task: TASK-013
Status: Completed

# TASK-013: Device Serial Redaction

## Objective

Keep the test phone's serial number out of the repository and its history.

## Background

Five records migrated in TASK-010 contained the serial, and it was committed locally. `FLUTTER_LIVE_TESTING.md` and `.vscode/launch.json`, both untracked, also contained it. The branch had not been pushed.

## Requirements

- No commit on the branch contains the serial.
- No file that Git can add contains the serial.
- F5 debugging on the owner's machine keeps working.

## Scope

- History of `chore/harness-reset` (renamed `dev` afterwards) from TASK-010 onward.
- `.gitignore`.
- `FLUTTER_LIVE_TESTING.md` (edited, left untracked for the owner to commit).
- Commit hashes in the TASK-010, TASK-011, and TASK-012 records.

## Out of Scope

App code, the owner's other uncommitted changes, and `.vscode/launch.json` content.

## Assigned Roles

- Advisor: Main agent, same session
- Dev: Main agent, same session
- QA Review: Self-check, not independent
- Docs: Main agent, same session

## Implementation Plan

1. Rebuild the three commits from TASK-010 onward with the serial replaced by `<device-id>`, keeping author, dates, and messages. Approved by the owner before the rewrite.
2. Update the commit hashes recorded in the task files.
3. Replace the serial in `FLUTTER_LIVE_TESTING.md` with `<device-id>`.
4. Ignore `.vscode/launch.json`, which needs the real serial to work.

## Dependencies

TASK-010 and TASK-012.

## Acceptance Criteria

- [x] `git log --all -S<serial>` returns nothing.
- [x] `git grep --untracked <serial>` returns nothing.
- [x] `git check-ignore` reports `.vscode/launch.json` as ignored.
- [x] The app diff and the untracked file list are unchanged by the rewrite.

## Testing Requirements

Git searches of history and of the working tree. No app code changed, so analysis and tests were not rerun.

## QA Results

Self-check, not independent.

- History: no commit on any ref adds or removes the serial, and no commit message contains it.
- Rewritten commits differ from the originals in 14 lines across 7 files: the serial in five records and the commit hashes in two.
- Working tree: the serial is found only in `.vscode/launch.json`, which is ignored.
- The diff of app files against `HEAD` and the list of untracked files were identical before and after the rewrite.

## Documentation Updates

TASK-012 notes, `FLUTTER_LIVE_TESTING.md`.

## Git Commit

- Commit Message: chore(security): ignore local launch config [TASK-013]
- Commit Hash: e944670

## Final Report

The serial is gone from the branch history and from every file Git can add. The local launch config is ignored and still works.

## Notes and Limitations

- New hashes: TASK-010 `15dcc45`, TASK-011 `d8b47a9`, TASK-012 `d19314b`. The old commits remain in the local reflog until Git prunes them. No ref points to them, so a push does not send them.
- The five redacted records differ from their original `.team/` checksums by the serial token only.
- `.vscode/launch.json` is no longer shareable through Git. On another machine, pick the device in VS Code or recreate the file.
- `FLUTTER_LIVE_TESTING.md` is still untracked. It belongs to the owner's uncommitted work.
