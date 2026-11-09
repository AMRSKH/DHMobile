Author: AI Agent
Date: 2026-11-09
Task: TASK-010

# Tasks

Every non-trivial task has one Task ID and one file in this folder. Do not create task files for trivial operations.

## File names

`TASK-{NUMBER}-{SHORT-DESCRIPTION}.md`, for example `TASK-013-fix-player-buffering.md`.

- Three-digit, zero-padded, sequential numbers.
- Lowercase kebab-case descriptions.
- Inspect this folder first and take the number after the highest one here. Files in `archive/` do not count.
- Never reuse an ID or overwrite a task file.
- One logical task per ID. Use subtasks (`TASK-013-A`, `TASK-013-B`) only when genuinely necessary.

## Header

Every new task file begins with this, copied from `task_template.md`:

```markdown
Author: AI Agent
Date: YYYY-MM-DD
Task: TASK-013
Status: Pending

# TASK-013: Task Title
```

## Status

| Status | Meaning |
| --- | --- |
| Pending | Recorded, not started |
| In Progress | Being worked on |
| In Review | Implementation done, under QA or awaiting commit |
| Blocked | Cannot proceed; the reason is in the file |
| Completed | Verified and committed |

Never mark an incomplete task as `Completed`.

## Commit hash

A commit cannot contain its own hash. After committing, set `Status: Completed` and fill in `Commit Hash`, then include that edit in the next task's commit.

## Existing records

- `TASK-001` to `TASK-007` predate this format and are kept unchanged. They track status with checkboxes.
- `TASK-001-audit-full-workflow.md` is the worked example of a real task.
- `archive/dev`, `archive/qa`, and `archive/review` hold the desk notes from those tasks.
