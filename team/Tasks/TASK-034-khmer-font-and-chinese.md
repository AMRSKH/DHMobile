Author: AI Agent
Date: 2026-11-10
Task: TASK-034
Status: Completed

# TASK-034: Embedded Inter Khmer Looped font and Simplified Chinese

## Objective

Draw Khmer text with Inter Khmer Looped, embedded in the app (no CDN), and
add Chinese as a display language.

## Background

Owner `/task`, 2026-11-10: "Update Khmer font to Inter khmer Looped. embed it
not use cdn. and Add Chinese Language." Owner approved the download and
chose Simplified Chinese.

Inter Khmer Looped belongs to Grab's Inter Font Extensions
(github.com/grab/inter-font-extensions, SIL Open Font License 1.1). The
built fonts exist only in the release package
`inter-font-extensions-1.0.zip` (9,900,799 bytes, SHA256
`263dc103f2261e247d3ead812b7f501382487508ec3c0b6cd0bc23880e026b3f`,
release 1.0, 2024-11-27). It was downloaded to a temporary folder; only
three TTF weights and `OFL.txt` were copied into the project.

## Requirements

1. `assets/fonts/inter_khmer_looped/`: Regular (400), SemiBold (600), Bold
   (700) TTF and `OFL.txt`; declared in `pubspec.yaml`.
2. Theme `fontFamilyFallback: ['InterKhmerLooped']`: Latin keeps the platform
   font; every Khmer glyph (app text and show titles) uses the embedded font.
3. The OFL text is registered in the app's license list.
4. `AppLanguage.zh` ("ZH - 中文") with a full Simplified Chinese table.

## Dev Results

- Files: Regular 154,052 B, SemiBold 157,696 B, Bold 161,176 B (TrueType,
  header `00 01 00 00`), OFL.txt 4,409 B; about 470 KB in the APK.
- `AppTheme.khmerFontFamily`, theme fallback; `LicenseRegistry` entry in
  `main.dart`.
- `_zh` table for every `S` key; Settings header letter spacing only for
  English (Latin capitals), not for Khmer or Chinese.
- Tests: every language has every key and English's placeholders; Chinese
  texts contain Han characters (except the names line and the pure number
  line); `zh` code and label; font fallback in the theme; the font files
  exist, are TrueType, and are declared. 256 passed.

## Acceptance Criteria

- [x] Font embedded and declared, license bundled (tests).
- [ ] Khmer drawn with Inter Khmer Looped on the phone. Open: phone not connected.
- [x] Chinese selectable, every text translated (tests).
- [ ] Chinese checked on the phone. Open.
- [x] format, analyze, tests pass.

## QA Results

Independent `qa-review` subagent, two rounds (one review with TASK-031/033).

Round 1: Changes Requested. Round 2: **Accepted**.

| Severity | Finding | Action |
| --- | --- | --- |
| High | H2: AppBar takes `appBarTheme.titleTextStyle` without the text theme, so Khmer page titles had no fallback | Fixed: fallback named in `titleTextStyle`; test |
| Medium | M3: Chinese search hint suggested Chinese titles; the sites use English titles | Fixed: '搜索国漫（如 BTTH、Soul Land）…' |
| Low | L2: History showed "集 12" | Improved to "集数 12"; "第 12 集" would need a new key (open) |
| Low | L3: "时间表", ASCII "..." | Fixed: '更新表', '…' |
| Low | L6: OFL registered but the app has no license page | Accepted: OFL.txt ships in the APK |

Round 2 checks: analyze clean, 261 tests passed, format clean, AppBar and body text both get the fallback (QA scratch test).

## Git Commit

- Commit Message: `feat(app): embed Inter Khmer Looped and add Chinese [TASK-034]`
- Commit Hash: 104b0f1

## Notes and Limitations

- Committed together with TASK-033 and TASK-035 (see TASK-033 Notes for why).
- Open: check Khmer (also page titles) and Chinese on the phone.

- The Chinese texts are the main agent's translation; a native reader
  should review them.
- Chinese glyphs come from the phone's system font.
