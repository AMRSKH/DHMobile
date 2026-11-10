Author: AI Agent
Date: 2026-11-10
Task: TASK-021
Status: In Review

# TASK-021: Search every DonghuaCLI source, not only AnimeXin

## Objective

Make the app read the same donghua sites as DonghuaCLI
(https://dcli.pages.dev/, source https://github.com/Thanukamax/donghua-cli),
so a series missing or broken on AnimeXin can be found on another site.

## Background

Owner, 2026-11-10: the project started from DonghuaCLI and "can stream from
multiple resources, not only AnimeXin". Until now `streamProvider` was a
single `AnimeXinStreamProvider`.

DonghuaCLI v4.1.0 (`src/donghua_cli/sources/`) has six sources: DonghuaWorld,
LuciferDonghua, AnimeXin, DonghuaStream, AnimeKhor, LMAnime. All six use the
"AnimeStream" WordPress theme, so one parser covers them. Its stream side
hands embeds to yt-dlp/mpv; the app already has its own resolver for
OK.ru, Dailymotion, and Rumble.

Checked from this machine on 2026-11-10 (Python probe and a temporary live
Dart test, both not committed):

| Source | Search | Episodes | Streams |
| --- | --- | --- | --- |
| AnimeXin | yes | 166 for Renegade Immortal | 12 (OK.ru) |
| DonghuaWorld | yes | 114 | 0: Dailymotion only, 403 (see Notes) |
| LuciferDonghua | yes | 168 | 0: Rumble only, 403 |
| DonghuaStream | yes | 167 | 0: Rumble, Dailymotion |
| LMAnime | yes | 52 | 0: Dailymotion, same-site players |
| AnimeKhor | 403 "Bot Verification" | - | - |

## Requirements

1. One generic provider for AnimeStream-theme sites (search, episodes,
   streams), with the AnimeXin provider built on it and keeping its popular
   list for an empty query and its built-in fallback catalog.
2. A source list in the domain layer, in priority order, AnimeXin first.
   AnimeKhor is left out (bot check).
3. Search asks every source at once. A failing or slow (12 s) source is
   skipped. Results are merged: the best hit of every source first, the same
   series from several sources kept together, duplicate URLs dropped.
4. Episodes and streams go to the site the show or episode URL is on. An
   unknown host (old saved data) goes to AnimeXin.
5. Explore (schedule, new, popular) stays on AnimeXin.
6. Each search result shows the name of its source.
7. Settings About lists every source.

## Scope

- `lib/data/providers/anime_stream_site_provider.dart` (new, logic moved out
  of `animexin_stream_provider.dart`)
- `lib/data/providers/multi_source_provider.dart` (new)
- `lib/domain/models/content_source.dart` (new)
- `lib/data/providers/animexin_stream_provider.dart`
- `lib/features/search/search_controller.dart`, `search_screen.dart`
- `lib/features/settings/settings_screen.dart`, `lib/core/app_info.dart`
- Tests

## Out of Scope

- Cross-source failover inside the player (play episode N from another site
  when its own site has no stream).
- Settings to turn sources on or off, or reorder them.
- New stream hosts (Streamwish, Dood, and others DonghuaCLI leaves to yt-dlp).
- AnimeKhor, which answers with a bot check (DonghuaCLI uses `curl_cffi`
  browser TLS impersonation; nothing like it in Dart without a new package).
  DonghuaStream sits behind Cloudflare too, but answered plain requests on
  2026-11-10, so it is in the list.

## Assigned Roles

- Advisor: main agent
- Dev: main agent
- QA Review: `qa-review` subagent
- Docs: main agent

## Implementation Plan

1. Move the AnimeXin parsing into `AnimeStreamSiteProvider(id, name, baseUrl)`.
2. `AnimeXinStreamProvider extends AnimeStreamSiteProvider`.
3. `kContentSources` + `defaultSources()`.
4. `MultiSourceStreamProvider` with `mergeSearchResults` and
   `normalizeShowTitle`.
5. Wire `streamProvider`, source badge, About text.
6. Tests with in-memory HTML (no network).

## Dependencies

TASK-020 (committed `fa22927`) touched `settings_screen.dart` first.

## Acceptance Criteria

- [x] Search returns results from every reachable source, merged.
- [x] A failing or slow source does not fail the search.
- [x] Episodes and streams use the show's own site.
- [x] Explore unchanged (AnimeXin).
- [x] Source badge on search results; About lists the sources.
- [x] `dart format`, `flutter analyze --no-pub`, `flutter test --no-pub` pass.

## Testing Requirements

`test/multi_source_provider_test.dart`: source list, parsing of a trimmed
AnimeStream search and series page, host routing, merge order, skip of a
failing and a slow source. `test/search_screen_test.dart`: badge.
`test/settings_screen_test.dart`: About text.

## QA Results

Independent `qa-review` subagent: **Accepted** (no Critical or High). analyze
clean, 208 tests passed, format clean, tests do not touch the network,
AnimeXin behaviour preserved (search, fallback catalog, empty query to
popular, Explore, saved favorites and history routed by host).

| Severity | Finding | Action |
| --- | --- | --- |
| Medium | Stale search race: a slow older search (up to 12 s now) could overwrite a newer result | Fixed: request counter in `SearchController`, widget test |
| Low | Non-Latin titles all got the empty merge key | Fixed: such titles keep their own text, test |
| Low | Relative `href` would route to AnimeXin by mistake | Fixed: `absoluteUrl()` for search and episode links, tests |
| Low | No test for `streams()` routing | Fixed: test |
| Low | Docs: AGENTS.md said "scraped from AnimeXin"; task file said DonghuaStream was out of scope | Fixed |
| Low | `searchTimeout` 12 s < Dio receive 15 s: a stalled AnimeXin skips its fallback catalog | Accepted |
| Low | Fallback catalog card can rank above real results of other sites | Accepted (Requirement 1 keeps the catalog) |
| Low | Posters send `Referer: animexin.dev` for every site | Accepted: posters of the new sites loaded without a Referer check (curl, 2026-11-10) |
| Low | Old `catch (_) {}` around base64 decode, moved unchanged | Accepted (scraper skip) |
| Low | TLS bypass in `main.dart` now covers four more hosts | Open: TASK-022, owner decision |

The fixes after QA were checked by the new tests (214 passed), not by a
second QA round.

## Documentation Updates

- AGENTS.md Overview, Technology stack (playback row, also for TASK-020), and
  Architecture now name the five sources, `content_source.dart`,
  `PlayerEngine`, and `MultiSourceStreamProvider`.

## Git Commit

- Commit Message: `feat(sources): search every DonghuaCLI source [TASK-021]`
- Commit Hash:

## Final Report

Search asks AnimeXin, DonghuaWorld, LuciferDonghua, DonghuaStream, and LMAnime
at once and merges the results with a source badge on each card. Episodes and
streams come from the show's own site; Explore stays on AnimeXin. Settings
About lists the sources. Checks: format clean, analyze no issues, 214 tests
passed.

## Notes and Limitations

- Streams of the four new sites did not play from this machine. Their
  episodes are mostly on Dailymotion and Rumble.
  - Rumble: its embed API answers 403 to plain HTTP clients (also for
    AnimeXin's Rumble servers). Not fixable without browser TLS
    impersonation.
  - Dailymotion: the signed HLS master answers 403 to Dart's HTTP client on
    this Windows machine, while Python gets 200 for the same kind of URL. The
    cause is not known. It must be tested on a phone before it can be called
    working or broken.
- Search now waits for the slowest source, up to 12 s.
- `stream_resolver.dart` shows a formatting-only change in the working tree
  from a folder-wide `dart format`; it is not part of this task and is not
  committed.
