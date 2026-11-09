Author: AI Agent
Date: 2026-11-09
Task: TASK-009
Status: Completed

# TASK-009: Security Config and Pre-commit Hook

## Objective

Back the written safety rules with tool permissions and a tested Git hook.

## Background

Claude Code had no project permissions, no Git hook existed, and OpenCode's allow rules did not cover the Flutter SDK path used on the main machine, which is off PATH. `dart format` reports 19 of 33 files as unformatted at baseline.

## Requirements

- Abort commits with unformatted staged Dart files or secret-looking paths.
- Do not let the existing unformatted files block unrelated commits.
- No new dependencies.

## Scope

`.githooks/pre-commit`, `.gitattributes`, `.gitignore`, `.claude/settings.json`, `opencode.jsonc`.

## Out of Scope

Reformatting existing files. PATH changes on the machine.

## Assigned Roles

- Advisor: Main agent, same session
- Dev: Main agent, same session
- QA Review: Self-check here; independent QA in TASK-012
- Docs: Main agent, same session

## Implementation Plan

1. Write a POSIX `sh` hook that exports the staged content and checks that.
2. Force LF for hooks through `.gitattributes`.
3. Add deny rules for secrets, allow rules for checks and local commits, and ask rules for push and package changes.

## Dependencies

Dart SDK from the existing Flutter install.

## Acceptance Criteria

- [x] Unformatted staged Dart aborts the commit.
- [x] Formatted staged Dart passes.
- [x] The staged content is judged, not the working tree.
- [x] `.env` and `key.properties` abort; `.env.example` passes.
- [x] Non-Dart commits pass.
- [x] `.claude/settings.json` is valid JSON.

## Testing Requirements

Run the hook against real commits in a throwaway clone.

## QA Results

Self-check, not independent: 8 of 8 scenarios passed in a throwaway clone. The hook also ran against this repository through a temporary index.

## Documentation Updates

`AGENTS.md` describes the hook and the setup step.

## Git Commit

- Commit Message: chore(security): add pre-commit gate and tool permissions [TASK-009]
- Commit Hash: 36ec554

## Final Report

Pre-commit gate enabled and tested. Claude Code and OpenCode permissions added.

## Notes and Limitations

- `.claude/settings.json` deny rules were not exercised in this session, because Claude Code loads a newly created settings directory at session start. Verify in a new session.
- `Read` deny rules do not stop a shell command such as `cat` from reading a file. The `AGENTS.md` rule still applies.
- Windows path patterns in `opencode.jsonc` were not exercised against a live OpenCode shell prompt.
