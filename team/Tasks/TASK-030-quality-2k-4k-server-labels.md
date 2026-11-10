Author: AI Agent
Date: 2026-11-10
Task: TASK-030
Status: In Review

# TASK-030: 2K/4K quality and "SubLang-Source quality" server labels

## Objective

Add 2K (1440p) and 4K (2160p) to the quality choices and stream labels, and
show every server in the HQ menu as `<SubLang>-<Source> <quality>`, for
example `ENG-DonghuaStream 2K` or `IDN-AnimeXin 720p`.

## Background

Owner `/task`, 2026-11-10: "add Quality 2K, 4K ... Update at HQ to this
format "SubLang Source quality" example ENG-DonghuaStream 2K or
IDN-DonghuaStream 2K." Owner choice for servers whose name has no language:
`SUB` (multi-sub / all-sub servers: `MULTI`).

Today the menu shows the raw server name (for example "Hardsub English Ok.ru
AX 720p"), OK.ru qualities stop at 1080p (`quad` / `ultra` are not mapped),
and Settings offers Auto, 1080p, 720p, 480p.

## Requirements

1. OK.ru `quad` → 1440p, `ultra` → 2160p. Dailymotion variants already carry
   their height.
2. `StreamSource.sourceName`: the site the stream came from, set by the site
   provider.
3. Labels: language code (`ENG`, `IDN`, `MULTI`, `POR`, `SPA`, `THA`, `VIE`,
   else `SUB`), the source name, and the quality (`4K` for 2160p, `2K` for
   1440p, `Auto` for adaptive/multi-bitrate, else `1080p` and so on). Equal
   labels in one list get ` (2)`, ` (3)`.
4. Settings Default Quality: Auto, 4K, 2K, 1080p, 720p, 480p (stored as
   `2160p` / `1440p`). Picking falls back to the nearest available quality.

## Scope

`stream_source.dart`, `stream_resolver.dart` (OK.ru names),
`anime_stream_site_provider.dart`, `source_selection.dart`,
`settings_screen.dart`, tests.

## Out of Scope

Startup speed (TASK-031), Explore lists (TASK-032).

## Assigned Roles

- Advisor: main agent; owner decided the label fallback.
- Dev: main agent. QA Review: `qa-review` subagent. Docs: main agent.

## Acceptance Criteria

- [x] HQ menu shows `SubLang-Source quality` for every server.
- [x] 2K/4K in Settings; 2K/4K streams labelled as such.
- [x] format, analyze, tests pass.

## Dev Results

- `StreamSource.sourceName` (+ `copyWith`), set by `AnimeStreamSiteProvider.streams()` after the playability filter, so all five sources fill it.
- OK.ru `ultra` → 2160p, `quad` → 1440p. `stream_resolver.dart` was formatted as a whole (it was unformatted before; the hook needs changed files formatted); QA confirmed that mapping is the only behaviour change.
- `sourceLabel` / `sourceLabels` / `subLangCode` / `qualityName` in `source_selection.dart`; the HQ menu builds its labels once per opening.
- Settings Default Quality: Auto, 4K, 2K, 1080p, 720p, 480p (stored `2160p`, `1440p`).
- Tests: labels for real server names, numbering, 2K/4K picking, menu widget test (235 passed).

## QA Results

Independent `qa-review` subagent (one review with TASK-032): **Accepted**, no
Critical, High, or Medium. analyze clean, tests passed, format clean, no
control characters in lib/ or test/. Real server names give ENG, IDN, MULTI,
SUB, POR, SPA as intended; stored `2160p` / `1440p` fall back to the nearest
available quality; old stored values unchanged.

| Severity | Finding | Action |
| --- | --- | --- |
| Low | Old doc comment on `sourceLabel` | Fixed |
| Low | "Direct" / "Direct MP4" without height shown as Auto | Fixed: keeps the source's word; Auto only for adaptive/multi/default |
| Low | Picker's language rule (english/indo words) differed from the menu's (`ENG SUB` = ENG in the menu, "no language" in the picker) | Fixed: picker uses `subLangCode` (ENG/IDN wanted, SUB/MULTI neutral) |
| Low | `multi` matches widely ("Multi Audio") | Accepted, not seen in real names |
| Low | No test for OK.ru `quad`/`ultra` and for `sourceName` in `streams()` (network paths, no tests before) | Accepted |

## Git Commit

- Commit Message: `feat(player): 2K/4K quality and SubLang-Source labels [TASK-030]`
- Commit Hash:

## Notes and Limitations

- 2K/4K appear only when a server offers them (OK.ru `quad`/`ultra`, Dailymotion 1440/2160 variants); otherwise the nearest lower quality plays.
- Not yet checked on the phone; done with the device test of this batch.
