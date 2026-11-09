---
author: opencode
date: 2026-11-04
task: TASK-004
---

# TASK-004 — Review notes

## Findings first
- Episode-number regex was merging display text (`40 [248]` → `40248`): fixed via leading-digit parse.
- Duplicate episode rows in the detail grid (`EP 209` shown twice): fixed with URL-based dedupe.
- Gesture layer ordering vs PlayerControls was causing the earlier "gesture unresponsive / button blocking" symptom in the audit: restructured so the video surface is owned by the gesture overlay and all controls live in an outer Stack with an `IgnorePointer` scrim, matching the documented contract.
- PlayerControls clipping of the Next Episode / `1.0x` items fixed by expanding the time label and dropping the nested row.

## Changed files (summary)
- `lib/core/debug_log.dart` — new debug-gated logger.
- `lib/data/providers/animexin_stream_provider.dart` — episode parsing fix + dedupe; diagnostic logging.
- `lib/features/player/*` — layout fix; DLog instrumentation; gesture layer moved over the video only.
- `lib/features/detail/detail_screen.dart`, `lib/features/search/search_controller.dart`, `lib/features/search/search_screen.dart`, `lib/features/library/library_screen.dart`, `lib/data/storage/storage_service.dart`, `lib/main.dart` — wiring logs.
- `test/gesture_overlay_test.dart` — updated to the new stacking contract; all 12 tests green.

## Verdict
`flutter analyze` and `flutter test` pass; release APK built. No `git push` performed. Kept under scope, no new packages.
