---
author: opencode
date: 2026-11-04
task: TASK-004
---

# TASK-004 — QA results

## Device
- SM A546E, serial <device-id>, Android 17 (API 37), 1080x2340 portrait / 2340x1080 landscape.

## Commands (last run)
- `dart format` on every changed file: pass (0 changes on already-formatted files).
- `flutter analyze`: pass (no issues).
- `flutter test`: pass (12/12).
- Release build: `flutter build apk --release` → all Gradle tasks OK, 184.5 MB.

## Flows exercised with the instrumented build
- Cold start, featured grid, poster load (3 title search cells).
- Search: `swallow the star` → 7 unique results; empty refresh path.
- Detail: `Swallowed Star Season 5`, 40 episodes unique (was duplicated), correct EP 40 max after number parse fix.
- Open episode 36244: sources resolved (8 servers), player buffer overlay showed "Connecting to ...", seek ±10s, server switch, pause/resume, double-tap left/right.
- No `E/flutter` exceptions during the 7-minute run.
- Favorites toggle (logged), history, settings persisted `Auto` quality.
- Background/foreground lifecycle did not crash (`player.lifecycle` events present).
- Volume swipe and brightness swipe operated the native channel.

## Noted
- 1 player watchdog fired (src 0, 144p Ok.ru) and advanced to src 1 correctly.
- Low/known issues documented above not fixed (a11y labels, stale counts, dead EP-1 mirrors, TLS bypass, disk cache).
