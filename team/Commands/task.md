Author: AI Agent
Date: 2026-11-09
Task: TASK-011

# /task: Main Task Orchestration

**Usage:** `/task <description>` starts a task. `/task TASK-013` resumes one.

Follow `AGENTS.md` throughout. Delegate to the `advisor`, `dev`, `qa-review`, and `docs` subagents when your tool has them. Otherwise do each stage yourself, in order. Never claim independent agents were used when they were not.

## 1. Understand

- Analyze the request and inspect the relevant files.
- Run `git status`, and note existing changes that are not part of this task.
- Identify dependencies and risks.
- Ask only if the requirement is unclear, or if a decision needs approval.

## 2. Create the task record

- Inspect `team/Tasks/` and take the number after the highest `TASK-*.md` there.
- Create `team/Tasks/TASK-{NNN}-{short-description}.md` from `task_template.md`. Never overwrite a file.
- Fill it in and set `Status: In Progress`.
- When resuming, read the existing file and continue from its status.

## 3. Advisor

Run `advisor.md`. Record the recommendation in the task file. Skip this only for small, obvious changes, and write that it was skipped.

## 4. Dev

Run `dev.md`. Then set `Status: In Review`.

## 5. QA Review

Run `qa-review.md`, independently when possible. Record the result in `QA Results`.

If the verdict is **Changes Requested**, return the findings to Dev, fix them, rerun the checks, and repeat QA until accepted or blocked. Never bypass QA to complete a task. If blocked, set `Status: Blocked`, record why, and stop.

## 6. Docs

Run `doc.md`. If no document is affected, record that.

## 7. Final validation

Run and record real results:

1. `dart format` on changed Dart files.
2. `flutter analyze --no-pub`.
3. `flutter test --no-pub`.
4. A build check, when the change can affect it (for example `android/` or `pubspec.yaml`).
5. `git status` and `git diff`: no secrets or unrelated changes.

If a check fails, return to Dev. Do not commit. If a check cannot be run, record why.

## 8. Commit

- Stage only this task's files, by name. Leave unrelated changes alone.
- Commit locally without asking, with the Task ID:

  ```text
  fix(player): resolve infinite buffering [TASK-013]
  ```

- Never use `--no-verify`. If the hook fails, fix the cause and commit again.
- Never push without explicit approval.
- Afterward, write the hash and `Status: Completed` to the task file. That edit is included in the next task's commit.

## 9. Final report

Summarize the Task ID and title, what was implemented, files changed, QA results, tests and validation, the commit hash, and remaining limitations.
