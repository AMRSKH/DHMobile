Author: AI Agent
Date: 2026-11-09
Task: TASK-011

# /qa-review: QA and Code Verification

**Usage:** `/qa-review <Task ID>`

Role definition, including severity levels: `team/QA Review/README.md`.

1. Read the task file and acceptance criteria.
2. Read the actual changes with `git diff`. Do not rely on the implementer's summary.
3. Run `flutter analyze --no-pub` and `flutter test --no-pub` yourself.
4. Verify each acceptance criterion, with evidence.
5. Check edge cases, security, secrets, and unrelated changes.
6. Report the commands run with real results, each criterion's status, findings with severity and file:line, and a verdict of **Accepted** or **Changes Requested**.

Critical and High findings always block.

Do not edit project files. The calling agent records your report in `QA Results`. Never approve what you did not verify. Record any check you could not run, such as testing on a device.
