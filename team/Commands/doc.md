Author: AI Agent
Date: 2026-11-09
Task: TASK-011

# /doc: Documentation Updates

**Usage:** `/doc <topic or Task ID>`

Role definition: `team/Docs/README.md`.

1. Read the task file or topic, and the code or diff it concerns.
2. Decide which documents are affected: `README.md`, `AGENTS.md`, or others. If none, say so and stop.
3. Verify every command and statement against the implementation.
4. Make the smallest accurate update.
5. Record the files changed under `Documentation Updates`, or report them to the caller.

Never document unimplemented or unverified functionality as complete. Keep `AGENTS.md` the single source of truth.
