Author: AI Agent
Date: 2026-11-10
Task: TASK-018
Status: In Review

# TASK-018: Underline tabs for the Explore day row

## Objective

Give the Explore day row (Mon | Tue | ...) the same underline tab style as the category tabs of TASK-017.

## Background

Owner request, 2026-11-10: "Make change on ជួរថ្ងៃ (ច័ន្ទ | អង្គារ …) too".

State before the task (commit `d77e638`): `_DayRow` in `lib/features/explore/explore_screen.dart` draws seven `InkWell` text labels separated by `|`, selected white bold, others `Colors.white38`, 44 px high. `UnderlineTabBar` in `lib/core/widgets/underline_tab_bar.dart` already exists and is used for the categories.

## Requirements

1. The day row uses `UnderlineTabBar`: no `|` separators, no ink splash, active white w600 with the red underline, inactive `#AAAAAA` w400.
2. Labels stay `strings.weekdayShort(day)` in English and Khmer. Tapping a day still calls `selectWeekday(day)` with 1 to 7.
3. The selected day is visible without scrolling when the screen opens and when it changes. Seven Khmer labels with 24 px gaps can be wider than a phone, so today (for example Sunday) could start off screen.

## Scope

- `lib/features/explore/explore_screen.dart` `_DayRow`.
- `lib/core/widgets/underline_tab_bar.dart`: scroll the selected tab into view.
- Tests in `test/underline_tab_bar_test.dart` and `test/explore_screen_test.dart`.

## Out of Scope

- The Library tabs and the bottom navigation.
- Any controller or data change.

## Assigned Roles

- Advisor: skipped. Small change that reuses the TASK-017 widget.
- Dev: `dev` subagent.
- QA Review: `qa-review` subagent.
- Docs: main agent.

## Implementation Plan

1. `_DayRow` builds `UnderlineTabBar` with the seven weekday labels, `selectedIndex: selected - 1`, `onSelected: (i) => onSelected(i + 1)`.
2. `UnderlineTabBar` brings the selected tab into view after the first layout and after `selectedIndex` changes (for example `Scrollable.ensureVisible` on the selected tab's context, animated on change, immediate on first layout). No effect when everything fits.
3. Tests: day selection through the new widget, Khmer labels, the selected tab visible in a narrow width at start and after a change.

## Dependencies

TASK-017.

## Acceptance Criteria

- [x] The day row has no `|` separators and uses the underline style.
- [x] Tapping a day selects it, in English and Khmer.
- [x] The selected day is visible when the row overflows, at start and after a change.
- [x] The category tabs still pass their TASK-017 tests.
- [x] `flutter analyze --no-pub` passes.
- [x] `flutter test --no-pub` passes.

## Testing Requirements

Widget tests as in the plan. Device check if the phone is connected.

## Dev Results

By the `dev` subagent:

- `lib/features/explore/explore_screen.dart`: `_DayRow` wraps `UnderlineTabBar` (labels `weekdayShort(1..7)`, `selectedIndex: selected - 1`, `onSelected: i + 1`). The separators, `InkWell`, and the 44 px box are gone.
- `lib/core/widgets/underline_tab_bar.dart`: now a `StatefulWidget` with its own `ScrollController` and one `GlobalKey` per tab. It jumps the selected tab into view after the first layout and animates to it (200 ms, easeOut) when the selection changes, using the smallest offset that shows the tab with its 16 px padding.
- Tests: a "keeps the active tab in view" group in `test/underline_tab_bar_test.dart`, and day-row tests in `test/explore_screen_test.dart`.

Deviation: the offset is computed with `RenderAbstractViewport.getOffsetToReveal` instead of `Scrollable.ensureVisible`, so the padding stays visible and the scroll is minimal.

## QA Results

### Round 1: Accepted, with Lows

By the `qa-review` subagent. Mutations of the first jump, the change scroll, the weekday mapping (three ways), the padding, the reveal-at-end branch, and the duration were all caught. Edge probes (right-to-left, text scale 1.6, rapid changes, dispose while pending, two bars on one screen, label count change) passed.

| ID | Severity | Finding | Decision |
| --- | --- | --- | --- |
| L1 | Low | A label change at the same index (language switch while Explore stays alive) or a width change (rotation) did not re-reveal the selected tab | Fixed by Dev |
| L2 | Low | The narrow Khmer Explore test used `ensureVisible` before the tap and depended on today's date | Fixed by Dev |
| L3 | Low | The gap used `EdgeInsets.only(right:)`, wrong in right-to-left (from TASK-017) | Fixed by Dev |
| L4 | Info | The clamp is never needed in practice | Kept as a guard |

Fixes: `didUpdateWidget` jumps to the tab when the labels change at the same index; a `LayoutBuilder` jumps when the width changes (not on the first build, no loop); the gap is `EdgeInsetsDirectional.only(end:)`. New tests for each, and the Explore test drives the days through the controller starting on Sunday.

### Round 2: Accepted

Re-check by the same subagent in a fresh copy. Mutations removing the labels check, removing the width check, revealing on every build, going back to `EdgeInsets.only(right:)`, and removing the change scroll were all caught, the last one now also by the Explore test. No reveal loop after settling. Checks: format clean, analyze clean, `+182: All tests passed!`, real-font tests ran.

| ID | Severity | Finding | Decision |
| --- | --- | --- | --- |
| N-L1 | Low | The `LayoutBuilder` makes the bar unusable inside `IntrinsicHeight` or `IntrinsicWidth` | Accepted: no caller uses intrinsics. Recorded as a limitation |

## Documentation Updates

No document affected: `AGENTS.md` already lists the underline tab bar under `core/widgets/` (TASK-017), and no document describes the day row.

## Final Validation

| Check | Result |
| --- | --- |
| `dart format` on the 4 changed Dart files | `Formatted 4 files (0 changed)` |
| `flutter analyze --no-pub` | `No issues found! (ran in 9.7s)` |
| `flutter test --no-pub` | `00:16 +182: All tests passed!` |
| Build | Not run: no `android/` or `pubspec.yaml` change |
| `git status` | This task's files and the TASK-017 record completion edit |

## Git Commit

- Commit Message: feat(explore): use underline tabs for the day row [TASK-018]
- Commit Hash:

## Final Report

The Explore day row now uses the same underline tabs as the categories: no separators, active day white w600 with the red underline, others `#AAAAAA`. The tab bar keeps the selected tab in view at start, on a change, on a language change, and on a width change. QA accepted it in round 2. 182 tests pass.

## Notes and Limitations

- Not checked on the device (the phone was disconnected): Khmer widths, the scroll feel, rotation, the language switch while Explore is open.
- `UnderlineTabBar` cannot sit inside `IntrinsicHeight` or `IntrinsicWidth` (QA N-L1).
- The day row is now 48 px high instead of 44 px.
