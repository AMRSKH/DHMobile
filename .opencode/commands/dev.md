---
description: Implement a task from .team/tasks
agent: build
---

Implement task $ARGUMENTS.

Steps:

1. Read the task file in `.team/tasks/` and `AGENTS.md`.
2. Make small, focused changes that match the project architecture.
3. Run `dart format` on changed Dart files, then `flutter analyze` and `flutter test`.
4. Write a short note to `.team/dev/` with the author/date/task header.
5. Update the task status.

Do not push to git or install packages without asking. Ask when scope is unclear.
