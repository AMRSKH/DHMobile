Author: AI Agent
Date: 2026-11-10
Task: TASK-017
Status: Completed

# TASK-017: YouTube-style underline tabs for the Explore categories

## Objective

Replace the pill tabs of the Explore categories with a minimal tab bar: plain text tabs and a red underline under the active one.

## Background

Owner request, 2026-11-10 (summary): remove the pill backgrounds, borders, and rounded containers; active text pure white and medium or semibold; inactive text muted gray and normal; the same font size in both states so nothing shifts; a red line of 2 to 3 px under the active tab, as wide as its text, at the bottom edge; a horizontal row that scrolls without a scrollbar when it overflows; even spacing (24 or 32 px); a transparent or dark background; a smooth transition when the active tab changes. The request uses Tailwind terms. The app is Flutter, so they are mapped to Flutter widgets.

State before the task (commit `10d59ca`): `lib/features/explore/explore_screen.dart` `_CategoryRow` draws three `ChoiceChip`s (Schedule, New Series, Popular) with a red filled active chip and gray filled inactive chips. It is the only pill tab bar in the app. The Library `TabBar` already uses an underline, and the Explore day row is plain text with separators.

## Requirements

1. No background, border, or rounded container on any tab.
2. Active text `#FFFFFF`, `FontWeight.w600`. Inactive text `#AAAAAA`, `FontWeight.w400`. Same font size.
3. No layout shift when a tab becomes active or inactive.
4. Active indicator: `#FF0000`, 3 px high, rounded ends, as wide as the label text, at the bottom of the tab.
5. Horizontal row, 24 px between tabs, scrolls when it overflows, no scrollbar.
6. Transparent background, so the dark scaffold shows through.
7. Animated change of the text color and the indicator, about 200 ms.

## Scope

- A reusable widget in `lib/core/widgets/`.
- `_CategoryRow` in `lib/features/explore/explore_screen.dart` uses it.
- Tests for the widget, and `test/explore_screen_test.dart` updated.

## Out of Scope

- The Explore day row and the Library `TabBar`. They have no pills.
- The bottom navigation bar.
- Any change to the Explore controller or data.

## Assigned Roles

- Advisor: skipped. Small, visual change in one widget with a clear specification.
- Dev: `dev` subagent.
- QA Review: `qa-review` subagent.
- Docs: main agent checks whether a document is affected.

## Implementation Plan

1. `lib/core/widgets/underline_tab_bar.dart`: `UnderlineTabBar({required List<String> labels, required int selectedIndex, required ValueChanged<int> onSelected})`.
2. Each tab reserves the width of its label in the active weight, so the switch between weights does not move anything.
3. The indicator is a 3 px rounded bar under the label, shown with an animation for the active tab.
4. Tap target at least 44 px high (room for Khmer text), with `Semantics(selected:, button: true)`, no splash pill.
5. `_CategoryRow` builds `UnderlineTabBar` from `ExploreCategory.values`.
6. Tests: widget test file for `UnderlineTabBar`, and the Explore screen test helper updated.

## Dependencies

None.

## Acceptance Criteria

- [x] No `ChoiceChip` or filled container left in the Explore category row.
- [x] Active label white and w600, inactive `#AAAAAA` and w400, same size.
- [x] A tab keeps its width when it becomes active.
- [x] A 3 px `#FF0000` rounded indicator sits under the active label only, as wide as the label.
- [x] 24 px between tabs, horizontal scroll without a scrollbar.
- [x] The change animates (about 200 ms).
- [x] Tapping a tab still selects the category, in English and Khmer.
- [x] `flutter analyze --no-pub` passes.
- [x] `flutter test --no-pub` passes.

## Testing Requirements

- Widget tests: colors and weights, indicator present only under the active tab and as wide as its label, tab width the same in both states, tap calls `onSelected`, semantics selected flag, no scrollbar.
- `test/explore_screen_test.dart`: category selection through the new widget.
- Device check if the phone is connected.

## Dev Results

By the `dev` subagent:

- Added `lib/core/widgets/underline_tab_bar.dart`: `UnderlineTabBar`. Scroll view without scrollbar, 16 px side padding, 24 px gaps. Each tab: `Semantics(button, selected)`, `GestureDetector`, min height 44, a Stack of an invisible w600 copy (sets the width) and the visible `AnimatedDefaultTextStyle` label, and a 3 px `#FF0000` indicator with radius 1.5 that animates in opacity and horizontal scale over 200 ms.
- Changed `lib/features/explore/explore_screen.dart`: `_CategoryRow` uses `UnderlineTabBar`. No `ChoiceChip` left.
- Changed `test/explore_screen_test.dart`: the selected helper reads the tab semantics, and the Khmer test switches a tab.
- Added `test/underline_tab_bar_test.dart`, 12 tests.

Deviations: the width holder is a raw `RichText` in `ExcludeSemantics` and `Opacity(0)`, so `find.text(label)` still finds one widget per tab. The no-scrollbar test injects a scroll behavior that adds scrollbars, since the default never shows one on a horizontal view.

Checks reported by Dev: format `Formatted 4 files (0 changed)`, analyze `No issues found!`, test `+165: All tests passed!`.

## QA Results

### Round 1: Changes Requested

By the `qa-review` subagent. The code met every requirement QA could check. A real-font test in a copy proved the w600 reservation (tab 76.05 px in both states at scale 1.0, 121.69 px at 1.6).

| ID | Severity | Finding | Decision |
| --- | --- | --- | --- |
| F1 | Medium | The no-shift test cannot fail: the test font draws all weights at the same width. Emptying the holder or setting it to w400 keeps 12/12 passing | Returned to Dev: real Roboto test at scale 1.0 and 1.6 |
| F2 | Low | Removing the holder's `textScaler` is not caught. At scale 1.6 the tab would shift (119.79 to 121.69 px) | Covered by the F1 fix |
| F3 | Low | Tap target 44 px, below Android's 48 dp guideline | Returned to Dev: 48 |
| F4 | Low | `ExcludeSemantics` adds nothing, `Opacity(0)` already drops semantics | Kept, comment to be accurate |
| F5 | Low | Test helper still named `_chipSelected` | Returned to Dev: rename |

Other mutations (scrollbar, zero duration, wrong tap index, tap height, gap) were all caught. Edge cases in a copy passed: fast switches, a language change mid-animation, label count change, out-of-range index, dispose mid-animation, right-to-left with bold text. QA checks: format clean, analyze clean, `+165: All tests passed!`.

### Dev results, round 2

The `dev` subagent fixed F1 to F5: a "with a real font" test group loads Roboto from the Flutter SDK and compares tab rects at text scale 1.0 and 1.6, the tap target minimum is 48 px, the hidden-copy comment is accurate, and the Explore helper is `_tabSelected`. Dev showed in a copy that the new tests fail when the holder text is emptied (both scales) or its text scale is removed (scale 1.6).

### Round 2: Accepted

Re-check by the same `qa-review` subagent. The real-font tests run (not skipped) and fail on both mutations, the 48 px mutation is caught, F4 and F5 are done. Checks: format clean, analyze clean, `+166: All tests passed!`.

| ID | Severity | Finding | Decision |
| --- | --- | --- | --- |
| N1 | Low | If the SDK's Roboto files were missing, the real-font tests would be skipped (`~2`) and a regression would pass | Accepted: the SDK always ships these files and `flutter test` sets `FLUTTER_ROOT` |

## Documentation Updates

By the main agent (small change, no `docs` subagent): `AGENTS.md` structure line for `core/widgets/` now names the underline tab bar. No other document describes the Explore tabs.

## Final Validation

| Check | Result |
| --- | --- |
| `dart format` on the 4 changed or added Dart files | `Formatted 4 files (0 changed)` |
| `flutter analyze --no-pub` | `No issues found! (ran in 9.1s)` |
| `flutter test --no-pub` | `00:17 +166: All tests passed!` |
| Build | Not run: no `android/` or `pubspec.yaml` change |
| `git status` | This task's files, `AGENTS.md`, and the TASK-016 record completion edit (included as AGENTS.md asks) |

## Git Commit

- Commit Message: feat(explore): replace pill tabs with underline tab bar [TASK-017]
- Commit Hash: d77e638

## Final Report

The Explore categories use a new `UnderlineTabBar`: plain text tabs, active white w600, inactive `#AAAAAA` w400 at the same size, a 3 px red rounded underline as wide as the active label, 24 px gaps, horizontal scroll without a scrollbar, and a 200 ms transition. Tabs keep their width when they change state, proven with a real font. QA accepted it in round 2. 166 tests pass.

## Notes and Limitations

- Not checked on the device (the phone was disconnected): rendering, Khmer glyphs, animation feel, TalkBack.
- The underline red is `#FF0000` as asked, while the rest of the app uses `#E50914`.
- The day row and the Library tabs keep their own style.
