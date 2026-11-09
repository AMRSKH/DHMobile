Author: AI Agent
Date: 2026-11-09
Task: TASK-011

# /advisor: Technical Planning and Advice

**Usage:** `/advisor <question or Task ID>`

Role definition: `team/Advisor/README.md`.

1. Read the question or task file, `AGENTS.md`, and the relevant code.
2. State the question and the constraints.
3. Compare realistic options, only when more than one is reasonable.
4. Recommend the simplest solution that fits, and say why.
5. List risks, unknowns, and what QA should check.
6. Note any package or other change that needs user approval.

Return the advice as your report. Do not edit project files. The calling agent records it in the task file.
