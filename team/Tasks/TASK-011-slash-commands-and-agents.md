Author: AI Agent
Date: 2026-11-09
Task: TASK-011
Status: Completed

# TASK-011: Slash Commands and Agents

## Objective

Provide `/task`, `/advisor`, `/dev`, `/qa-review`, and `/doc`, with real subagents, for the tools used on this repository.

## Background

The old OpenCode `/task` only created a file, `/qa` and `/review` were separate, and Claude Code had no commands or agents.

## Requirements

- One tool-neutral playbook per command.
- Thin wrappers in each tool's documented location.
- Confirm discovery before claiming a command works.

## Scope

`team/Commands/`, `.claude/commands/`, `.claude/agents/`, `.opencode/commands/`, `.opencode/agents/`.

## Out of Scope

Cursor and Antigravity configuration: no evidence these are used on this repository.

## Assigned Roles

- Advisor: Main agent, same session
- Dev: Main agent, same session
- QA Review: Self-check here; independent QA in TASK-012
- Docs: Main agent, same session

## Implementation Plan

1. Write the playbooks, covering the nine `/task` stages.
2. Add wrappers and agent definitions per tool, using OpenCode V2 and Claude Code formats.
3. Remove `.opencode/commands/qa.md` and `review.md`.
4. Check discovery through each tool's own interface.

## Dependencies

TASK-008, TASK-010.

## Acceptance Criteria

- [x] All five playbooks exist in `team/Commands/`.
- [x] OpenCode lists `advisor`, `dev`, `doc`, `qa-review`, and `task`.
- [x] OpenCode lists subagents `advisor`, `dev`, `docs`, and `qa-review`.
- [x] Only the orchestrator may commit; the OpenCode role agents have `git commit` and `git push` denied.
- [x] Claude Code discovery confirmed: the session listed all five commands and four agents after they were added.

## Testing Requirements

Query discovery from the tool. Evaluate effective OpenCode rules per agent.

## QA Results

Self-check, not independent.

- `opencode api GET /api/command` for this directory returned `advisor, dev, doc, qa-review, task` as project commands.
- `opencode debug agents` returned the four subagents with `mode=subagent`.
- A rule simulation over the resolved rules gave: edits denied for `advisor` and `qa-review`; commit and push denied for all role agents; commit allowed and `--no-verify` denied for `build`.

## Documentation Updates

`AGENTS.md` tool support table, `team/Commands/README.md`.

## Git Commit

- Commit Message: feat(team): add task workflow commands and subagents [TASK-011]
- Commit Hash: d8b47a9

## Final Report

Playbooks, wrappers, and subagents added and discovered by both tools. TASK-012 corrected the claims listed below.

## Notes and Limitations

- No command was executed end to end with a model.
- Codex has no repository command files here. It reads `AGENTS.md` and can follow `team/Commands/` directly.
- The body of commit d8b47a9 says role subagents cannot commit. That is enforced in OpenCode only; in Claude Code it is an instruction for `dev` and `qa-review`. See the table in `team/Commands/README.md`.
