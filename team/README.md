Author: AI Agent
Date: 2026-11-09
Task: TASK-010

# Team Workspace

How work is organized in DonghuaPlayer. Project rules live in `AGENTS.md`; this folder holds roles, task records, and command playbooks.

## Layout

| Path | Purpose |
| --- | --- |
| `Advisor/` | Technical guidance role |
| `Dev/` | Implementation role |
| `QA Review/` | Independent verification role |
| `Docs/` | Documentation role |
| `Tasks/` | One file per task, the template, and archived notes |
| `Commands/` | Tool-neutral playbooks behind the slash commands |

## Workflow

`/task` runs the full flow. The other commands run one stage.

1. **Understand:** read the request and the relevant code.
2. **Record:** create the task file with the next Task ID.
3. **Advisor:** recommend the simplest suitable approach.
4. **Dev:** implement it and run checks.
5. **QA Review:** verify independently. On failure, return to Dev and repeat.
6. **Docs:** update documentation that the change affected.
7. **Validate:** format, analyze, test, build when relevant, review the diff.
8. **Commit:** one local commit with the Task ID.
9. **Report:** summarize results and limitations.

## Delegation

Use real subagents when the tool supports them. Otherwise run each stage in sequence in the same agent, and write in the task file that QA was not independent.

## History

Records from before TASK-008 were created under the former `.team/` layout. Task files moved to `Tasks/`, and desk notes to `Tasks/archive/`. Their contents are unchanged, so paths inside them still say `.team/`.
