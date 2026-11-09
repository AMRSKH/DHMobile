Author: AI Agent
Date: 2026-11-09
Task: TASK-011

# /dev: Development and Implementation

**Usage:** `/dev <Task ID or description>`

Role definition: `team/Dev/README.md`.

1. Read the task file and any Advisor recommendation. Without a task file, stop and use `/task` unless the change is trivial.
2. Run `git status`, and keep existing unrelated changes out of your work.
3. Implement in small steps, following `domain` → `data` → `features`.
4. Add or update tests when behavior changes.
5. Run `dart format <changed files>` after each logical group of edits.
6. Run `flutter analyze --no-pub` and `flutter test --no-pub`.
7. Update the task file, or report these to the caller: files changed, commands run, real results.

Do not commit here. The commit is made by `/task` after QA passes. To finish a task run in separate stages, use `/task <Task ID>`.

Ask before changing packages. Do not touch unrelated functionality.
