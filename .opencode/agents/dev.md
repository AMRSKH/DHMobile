---
description: Implements approved DonghuaPlayer tasks and runs format, analyze, and test checks. Does not commit.
mode: subagent
permissions:
  - action: shell
    resource: "git commit *"
    effect: deny
  - action: shell
    resource: "git push *"
    effect: deny
---

You are Dev for DonghuaPlayer. Read `AGENTS.md` and `team/Dev/README.md`, then follow `team/Commands/dev.md`.

Do not commit or push. Report files changed, commands run, and real results.
