Author: AI Agent
Date: 2026-11-09
Task: TASK-012
Status: In Review

# TASK-012: Harness Validation and QA Fixes

## Objective

Have the rebuilt harness verified independently, and fix what that finds.

## Background

TASK-008 to TASK-011 were self-checked by the agent that wrote them.

## Requirements

Independent QA, with the Dev and QA loop repeated until accepted.

## Scope

`.githooks/pre-commit`, `.claude/`, `.opencode/`, `opencode.jsonc`, `AGENTS.md`, `team/`.

## Out of Scope

App code and the owner's uncommitted changes.

## Assigned Roles

- Advisor: Main agent, same session
- Dev: Main agent, same session
- QA Review: Separate subagents, in three rounds
- Docs: Main agent, same session

## Implementation Plan

1. Run independent QA against the full requirements.
2. Fix confirmed findings. Permission changes only narrow access, except that builds are now allowed as the specification requires.
3. Re-verify, and repeat until accepted.

## Dependencies

TASK-008 to TASK-011.

## Acceptance Criteria

- [x] Independent QA verdict is Accepted.
- [x] `flutter analyze --no-pub` passes.
- [x] `flutter test --no-pub` passes.
- [x] No app code changed on the branch.

## Testing Requirements

Hook edge cases in a throwaway clone, permission rules evaluated against the resolved config, analysis, and tests.

## QA Results

Independent review by separate subagents. Rule checks reimplemented each tool's matcher. No forbidden command was fired through a live permission prompt.

| Round | Verdict | Result |
| --- | --- | --- |
| 1 | Changes Requested | 2 High, 5 Medium, 10 Low |
| 2 | Changes Requested | H2 and M5 incomplete, 1 regression in OpenCode rule order |
| 3 | Accepted | All remaining items fixed; no new defect or rule-order regression |

Main fixes: root-level `secrets/` deny in OpenCode; `git commit` bypass flags and amend; non-ASCII paths in the secret check; failed exports no longer pass; corrected overstated claims in documentation.

Final results on the working tree, including the owner's uncommitted app changes:

- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub`: 12 passed.
- Hook: 20 of 20 scenarios behaved as expected in a throwaway clone.
- OpenCode: 23 of 23 rule probes as expected before round 2; round 3 confirmed the updated rules.

## Documentation Updates

`AGENTS.md`, `team/Commands/README.md`, TASK-008 and TASK-011 notes.

## Git Commit

- Commit Message: fix(security): close gaps found by independent QA [TASK-012]
- Commit Hash:

## Final Report

Pending commit.

## Notes and Limitations

- Permission globs are best effort. They cannot catch every combined short flag or `git add` form, or `git diff` falling back to no-index when a path is outside the repository, which can display a file without a prompt. The `AGENTS.md` rules still apply.
- `.claude/settings.json` deny rules were not exercised against a real secret-pattern file, because `AGENTS.md` forbids reading those paths.
- The hook checks hidden Dart paths only through directory formatting, which skips them. The project has none.
- `.claude/settings.json` has no PowerShell allow rules, so those commands prompt. This fails safe.
- Five archived records from before this harness contain a device serial number.
- `AGENTS.md` describes `debug_log`, `explore`, and `splash`, which are uncommitted working-tree files.
