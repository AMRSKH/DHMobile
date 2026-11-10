Author: AI Agent
Date: 2026-11-10
Task: TASK-032
Status: Completed

# TASK-032: Explore lists from every source

## Objective

Schedule, New Series, and Popular show the shows of every source, so no day
hides a show that one of the sites lists.

## Background

Owner `/task`, 2026-11-10: "Make sure every day all movie listed all no hide
anything from all source." Owner chose "Schedule + New + Popular".

Today Explore reads AnimeXin only. Schedule pages on 2026-11-10 (shows per
day): AnimeXin 6-14, DonghuaWorld 76-101, LuciferDonghua 12-32, LMAnime
18-40; together about 135-165 different titles a day. DonghuaStream's
schedule page has empty day lists in its HTML (filled by a script), so it
cannot be read; its `/anime/?order=latest|popular` lists work (20 each), as
on the other sites.

## Requirements

1. Schedule: every source that has the schedule page, merged per weekday,
   sorted by release time, the same URL once; a failing source is skipped,
   all failing is an error.
2. New Series and Popular: every source, merged like search results.
3. A source badge on Explore cards (the same widget as Search).

## Acceptance Criteria

- [x] Each weekday lists the shows of all readable sources (live check; device check with this batch).
- [x] New Series and Popular list all five sources.
- [x] format, analyze, tests pass.

## Dev Results

- `MultiSourceStreamProvider.schedule()/newSeries()/popular()` ask every
  source at once (15 s per source); a failing or slow source is skipped and
  logged, all failing throws the first error. `mergeSchedules()` keeps every
  entry per weekday, the same URL once, sorted by release time (stable;
  entries without a time keep source order at the end). New and Popular use
  `mergeSearchResults` (best hit of every source first).
- `SourceBadge` (`lib/core/widgets/source_badge.dart`) on Explore cards;
  Search uses the same widget instead of its private copy.
- Tests: merge order, dedupe, a source without schedule skipped, all failing
  throws, a slow source left out, popular/new merge (231 passed).
- Live check on 2026-11-10 (temporary test, not committed): schedule from 4/5
  sources (DonghuaStream skipped: "The schedule page has no shows"), shows
  per day Mon 155, Tue 136, Wed 160, Thu 147, Fri 170, Sat 140, Sun 152;
  929 of 1060 with a release time; no entry without a poster; 2.9 s.
  Popular 110 and New 110, from all five sources, 3.0 s.

## QA Results

Independent `qa-review` subagent (one review with TASK-030): **Accepted**, no
Critical, High, or Medium. `mergeSchedules` is a stable total order (UTC
times, index tiebreak); `_fromEverySource` cannot leave an unhandled future;
`GridView.builder` keeps ~150 cards per day light; the Explore controller and
Search's initial list are unchanged.

| Severity | Finding | Action |
| --- | --- | --- |
| Low | Posters of other sites are fetched with `Referer: animexin.dev` | Accepted: posters loaded without Referer checks (2026-11-10); check on the phone |
| Low | Explore now waits for the slowest source, up to 15 s if one hangs | Accepted (measured 2.9-3.0 s) |
| Low | One series can appear as several cards (one per site) | Intended: "no hide anything"; badges tell them apart. The 135-165 figure counts entries, not distinct series |

## Git Commit

- Commit Message: `feat(explore): list shows from every source [TASK-032]`
- Commit Hash: 90f978b
