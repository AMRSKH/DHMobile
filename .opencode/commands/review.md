---
description: Review changes for a task
agent: build
---

Review task $ARGUMENTS.

Steps:

1. Read the task, the diff, and `AGENTS.md`.
2. Check correctness, security, tests, and performance.
3. Confirm the formatter and tests were run.
4. Write findings to `.team/review/` with the author/date/task header.
5. Give a verdict: approve, approve with nits, or request changes.

Do not modify app code. Report findings only.
