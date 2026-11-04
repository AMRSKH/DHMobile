---
author: opencode
date: 2026-11-04
task: TASK-000
---

# Team workspace

This folder tracks work for DonghuaPlayer.

## Desks

| Desk | Folder | Purpose |
| --- | --- | --- |
| Dev | `.team/dev/` | Implementation notes and decisions |
| QA | `.team/qa/` | Test runs and results |
| Review | `.team/review/` | Code review findings |
| Advisor | `.team/advisor/` | Risks, options, recommendations |
| Docs | `.team/docs/` | Documentation notes |

## Tasks

- Every task lives in `.team/tasks/`.
- Start from `.team/tasks/_template.md`.
- Name files `TASK-<number>-<slug>.md`.

## Header rule

Every file in `.team/` starts with:

```yaml
---
author: <name>
date: YYYY-MM-DD
task: TASK-000
---
```

## Flow

1. `/task` creates the task.
2. `/dev` implements it and writes notes to `.team/dev/`.
3. `/qa` tests it and writes results to `.team/qa/`.
4. `/review` checks the change and writes findings to `.team/review/`.
5. `/advisor` is used for risks or decisions.
6. `/doc` updates docs and `.team/docs/`.
