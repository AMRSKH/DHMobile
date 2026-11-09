Author: AI Agent
Date: 2026-11-09
Task: TASK-008
Status: Completed

# TASK-008: Central Agent Instructions

## Objective

Make `AGENTS.md` the complete source of truth for all AI agents.

## Background

The previous `AGENTS.md` had no Git rules or Definition of Done, omitted `explore`, `splash`, and `core/debug_log.dart`, and did not say that Flutter is off PATH on the main machine.

## Requirements

Cover every section the harness specification lists, using only facts confirmed in the repository.

## Scope

`AGENTS.md`, `CLAUDE.md`.

## Out of Scope

App code. Files it refers to (`team/`, `.githooks/`, tool commands) arrive in TASK-009 to TASK-011.

## Assigned Roles

- Advisor: Main agent, same session
- Dev: Main agent, same session
- QA Review: Self-check here; independent QA in TASK-012
- Docs: Main agent, same session

## Implementation Plan

1. Confirm stack, layout, logging, and naming from the code.
2. Rewrite `AGENTS.md`.
3. Keep `CLAUDE.md` as a thin import and allow normal local commits.

## Dependencies

None.

## Acceptance Criteria

- [x] `AGENTS.md` covers overview, stack, architecture, setup, commands, standards, naming, error handling, security, Git, tasks, roles, Definition of Done, documentation.
- [x] Commands and paths match the repository.
- [x] `CLAUDE.md` imports `AGENTS.md` without duplicating it.

## Testing Requirements

Documentation only. No app code changes.

## QA Results

Self-check by the implementing agent: confirmed `DLog`, provider names, the TLS callback at `lib/main.dart:14`, and the feature folders. Not independent.

## Documentation Updates

This task is the documentation update.

## Git Commit

- Commit Message: docs(agents): rewrite central agent instructions [TASK-008]
- Commit Hash: 08cb2e5

## Final Report

`AGENTS.md` rewritten as the central instruction source. `CLAUDE.md` remains a thin import and now allows normal local commits.

## Notes and Limitations

`lib/core/debug_log.dart`, `lib/features/explore/`, and `lib/features/splash/` exist in the working tree but were not committed when this was written, so those references are accurate for the working tree only. `CLAUDE.md` also keeps four short safety reminders alongside the import.
