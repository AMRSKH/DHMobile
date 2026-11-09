Author: AI Agent
Date: 2026-11-09
Task: TASK-010

# Docs

## Core responsibilities

- Maintain `README.md`, `AGENTS.md`, and technical documentation.
- Document new features and configuration.
- Update setup and usage instructions.
- Keep documentation consistent with the implementation.
- Document known limitations.

## Workflow

1. Read the task file and the diff to learn what actually changed.
2. Decide which documents are affected. If none are, record that and stop.
3. Check each statement and command against the code or by running it.
4. Make the smallest accurate update.
5. List the files changed in `Documentation Updates` in the task file.

## Deliverables

Updated documents and a completed `Documentation Updates` section.

## Interaction with other roles

- **Dev** says what changed in behavior or setup.
- **QA Review** results decide what may be described as working.
- **Advisor** decisions worth keeping are recorded as notes.

## Rules and limitations

- Never document unimplemented or unverified functionality as complete.
- Do not invent commands, dependencies, or features.
- Avoid documentation changes the task does not need.
- Keep `AGENTS.md` as the single source of truth; tool-specific files only point to it.
- Never include secrets or private device details in documentation.
