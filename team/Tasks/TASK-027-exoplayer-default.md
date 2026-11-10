Author: AI Agent
Date: 2026-11-10
Task: TASK-027
Status: Completed

# TASK-027: ExoPlayer as the default player

## Objective

Make ExoPlayer the engine for users who never chose one; keep VLC selectable
in Settings > Video Player.

## Background

Owner decision, 2026-11-10 ("ExoPlayer default (Recommended)"). On the
owner's SM-A546E VLC at times drew grey or smeared frames (TASK-024 notes).
Such frames are no error, so the VLC to ExoPlayer fallback of TASK-020 never
starts, while ExoPlayer played cleanly in every test.

## Requirements

1. `PlayerEngine.defaultEngine = PlayerEngine.exo`; missing or unknown stored
   codes give it.
2. A user who chose VLC keeps VLC (stored code `vlc`).
3. Settings shows "ExoPlayer" by default; choosing VLC still works.

## Scope

`lib/domain/models/player_engine.dart`, `settings_controller.dart`,
`player_screen.dart` (initial field and a comment), tests, AGENTS.md.

## Acceptance Criteria

- [x] Default is ExoPlayer; stored `vlc` stays VLC (tests).
- [x] Settings tile and About read "ExoPlayer" by default; VLC can be chosen (widget test).
- [x] On the phone v1.0.8 plays with ExoPlayer (`ExoPlayerImpl: Init` in logcat, clean picture, resume at 10:18).
- [x] format, analyze, tests pass (220).

## QA Results

Independent `qa-review` subagent (one review with TASK-028): **Accepted**.
analyze clean, 220 passed, format clean. Stored `vlc` is only written by the
Settings dialog, so users who never chose move to ExoPlayer and those who
chose VLC keep it. Remaining `PlayerEngine.vlc` uses are real engine checks.

| Severity | Finding | Action |
| --- | --- | --- |
| Low | `settings_screen_test.dart` also holds the TASK-029 version line | Staged per task, so each commit passes its own tests |
| Low | Persistence test uses the in-memory store, not a Hive box | Accepted (same logic) |

## Git Commit

- Commit Message: `feat(player): make ExoPlayer the default player [TASK-027]`
- Commit Hash: 95132c1

## Notes and Limitations

- VLC stays fully supported and keeps its ExoPlayer fallback when chosen.
