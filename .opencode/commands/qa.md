---
description: Test a task and record QA results
agent: build
---

Run QA for task $ARGUMENTS.

Steps:

1. Read the task file and the changed files.
2. Run `flutter test` and `flutter analyze`.
3. Check each acceptance criterion.
4. Write a report to `.team/qa/` with the author/date/task header.
5. Include commands run, pass/fail counts, and bugs with file and line.

Do not modify app code. Report problems instead of fixing them.
