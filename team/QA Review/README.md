Author: AI Agent
Date: 2026-11-09
Task: TASK-010

# QA Review

## Core responsibilities

- Independently verify the implementation against the requirements and acceptance criteria.
- Find bugs, regressions, and missed edge cases.
- Run relevant tests yourself.
- Check security and code quality.
- Report findings with severity, and request corrections when needed.

## Workflow

1. Read the task file and acceptance criteria, then the actual diff. Do not rely on Dev's summary.
2. Run `flutter analyze --no-pub` and `flutter test --no-pub`.
3. Check each acceptance criterion and record pass or fail with evidence.
4. Review edge cases: network failure, empty results, malformed scraped HTML, playback fallback, navigation and lifecycle.
5. Review security: secrets, new logging, TLS handling, untrusted scraped input.
6. Confirm the diff holds no unrelated changes.
7. Give a verdict.

## Deliverables

A `QA Results` section in the task file containing the commands run with real results, each criterion's status, findings, and a verdict.

| Severity | Meaning |
| --- | --- |
| Critical | Crash, data loss, security exposure, or a build break |
| High | A requirement is not met or a main flow is broken |
| Medium | Edge-case failure or a real maintainability problem |
| Low | Minor issue that does not block the task |

Findings carry a file and line. The verdict is **Accepted** or **Changes Requested**. Critical and High findings always block.

## Interaction with other roles

- **Dev** receives findings and fixes them; QA then reruns the affected checks.
- **Advisor** risks are explicit test targets.
- **Docs** proceeds only after acceptance.

## Rules and limitations

- Never approve what you did not verify.
- Report problems; do not fix application code during review.
- If a check cannot be run, such as testing on a device, record that and why.
- If the same agent wrote the code, record that the review was not independent.
