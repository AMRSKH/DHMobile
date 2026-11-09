Author: AI Agent
Date: 2026-11-09
Task: TASK-010
Status: Completed

# TASK-010: Team Structure and Migration

## Objective

Replace `.team/` with the `team/` structure and keep all existing task records.

## Background

`.team/` had short desk READMEs and separate QA and Review desks. Five tasks and their notes were untracked, so deleting them would have been unrecoverable.

## Requirements

- Detailed role READMEs, task README, and template.
- Move all 19 records without changing their contents.
- Remove `.team/`.

## Scope

`team/`, removal of `.team/`.

## Out of Scope

Rewriting old records into the new header format. Command playbooks (TASK-011).

## Assigned Roles

- Advisor: Main agent, same session
- Dev: Main agent, same session
- QA Review: Self-check here; independent QA in TASK-012
- Docs: Main agent, same session

## Implementation Plan

1. Write the READMEs and template.
2. Move task files to `Tasks/`, and desk notes to `Tasks/archive/<desk>/`.
3. Compare checksums before removing anything from `.team/`.

## Dependencies

TASK-008.

## Acceptance Criteria

- [x] Each role README has responsibilities, workflow, deliverables, interaction, and rules.
- [x] Template and Task ID rules match the specification.
- [x] All 19 records are present with matching checksums.
- [x] `.team/` is removed.

## Testing Requirements

Checksum comparison. No app code changes.

## QA Results

Self-check, not independent. Checksums for 19 of 19 records matched after the move.

## Documentation Updates

`team/README.md` records where the old files went.

## Git Commit

- Commit Message: chore(team): replace .team with team structure [TASK-010]
- Commit Hash: 15dcc45

## Final Report

`team/` structure created, all 19 records moved with matching checksums, and `.team/` removed.

## Notes and Limitations

- `TASK-003` to `TASK-007` and their notes were untracked and are committed for the first time here.
- `TASK-001` serves as the example task, so no placeholder example was created.
- Old records still mention `.team/` paths.
