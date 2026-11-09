Author: AI Agent
Date: 2026-11-09
Task: TASK-011

# Commands

These playbooks are the single definition of each workflow command. Tool-specific command files are thin wrappers that point here, so a workflow change is made once.

| Command | Playbook | Claude Code | OpenCode |
| --- | --- | --- | --- |
| `/task` | `task.md` | `.claude/commands/task.md` | `.opencode/commands/task.md` |
| `/advisor` | `advisor.md` | `.claude/commands/advisor.md` | `.opencode/commands/advisor.md` |
| `/dev` | `dev.md` | `.claude/commands/dev.md` | `.opencode/commands/dev.md` |
| `/qa-review` | `qa-review.md` | `.claude/commands/qa-review.md` | `.opencode/commands/qa-review.md` |
| `/doc` | `doc.md` | `.claude/commands/doc.md` | `.opencode/commands/doc.md` |

## Subagents

| Agent | File-edit tools | Definition |
| --- | --- | --- |
| `advisor` | None | `.claude/agents/`, `.opencode/agents/` |
| `dev` | Yes | same |
| `qa-review` | None | same |
| `docs` | Yes | same |

`advisor` and `qa-review` return a report, and the calling agent writes it into the task file.

Only the `/task` orchestrator commits. What enforces this differs by tool:

| Restriction | OpenCode | Claude Code |
| --- | --- | --- |
| No edits for `advisor`, `qa-review` | Edit rule denied. A shell command could still write a file. | No edit tools. `qa-review` has a shell, which could still write a file. |
| No commit or push for role agents | Shell rules denied | Instruction only for `dev` and `qa-review`, which have a shell. `advisor` and `docs` have no shell. |

## Tools without slash commands

Tell the agent: "Read `team/Commands/task.md` and follow it for: <request>". Run the stages in sequence and record that QA was not independent.

## Adding a command

1. Write the playbook here.
2. Add a wrapper for each supported tool, in that tool's documented location.
3. Confirm the tool lists it before documenting it as available.
