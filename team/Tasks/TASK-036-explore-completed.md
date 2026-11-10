Author: AI Agent
Date: 2026-11-10
Task: TASK-036
Status: In Review

# TASK-036: Explore "Completed" tab with every completed series

## Objective

Add "Completed" after Schedule, New Series, and Popular in Explore, listing
every completed series of every source.

## Background

Owner `/task`, 2026-11-10: "at Schedule New Series Popular row add Completed
and list all completed movies here."

All five sites filter completed series with
`/anime/?status=completed&order=update`, paged by `?page=N` with a "Next"
link (`class="r"`). Counted on 2026-11-10 by following every page:

| Site | Pages | Completed series | Time (one after another) |
| --- | --- | --- | --- |
| AnimeXin | 7 | 209 | 9.9 s |
| DonghuaWorld | 11 | 217 | 14.9 s |
| DonghuaStream | 6 | 112 | 8.3 s |
| LMAnime | 4 | 71 | 11.9 s |
| LuciferDonghua | 1 | 15 | 2.2 s |
| Total | | 624 | |

## Requirements

1. A "Completed" tab (English, Khmer, Chinese).
2. Every page of every source: the first page of each site shows at once,
   later pages are added while the list is on screen, until every site has
   no "Next" page (a cap of 40 pages per site guards against loops).
3. Sites in parallel, pages of one site one after another; a failing page
   ends that site, a failing first page of every site is an error.
4. Merged like New Series / Popular, with the source badge; a thin bar shows
   that more pages are still coming.

## Scope

`lib/domain/providers/stream_provider.dart` (`completed()` stream),
`anime_stream_site_provider.dart`, `multi_source_provider.dart`,
`explore_controller.dart`, `explore_screen.dart`, `app_strings.dart`, tests
and the shared fake provider.

## Dependencies

Starts after the QA of TASK-031/033/034 (shared files).

## Assigned Roles

- Advisor: main agent. Dev: main agent. QA Review: `qa-review` subagent.
  Docs: main agent.

## Acceptance Criteria

- [x] Completed tab lists the series of all five sources, all pages (live: 624 of 624).
- [x] First results appear without waiting for every page (live: 1.4 s; all after 10.1 s).
- [x] format, analyze, tests pass (272). Phone check open (phone not connected).

## Dev Results

- `DonghuaStreamProvider.completed()`: a stream of the whole list so far.
- `AnimeStreamSiteProvider.completedPages()`: `/anime/?page=N&status=completed&order=update`,
  until no "Next" link (`hasNextPage`, `<a class="r">Next`) or no new
  series, at most 40 pages; a failing first page is an error, a later one
  ends the site. `completed()` accumulates the pages.
- `MultiSourceStreamProvider.completed()`: all sites at once (one listener
  per site, `listingTimeout` between pages), each page merged with
  `mergeSearchResults`; a failing site is left out; error only when no site
  gave a page; cancelling the stream cancels every site.
- Explore: `ExploreCategory.completed`, `completed` + `completedLoadingMore`
  in the state, a cancellable subscription (replaced on refresh, cancelled
  on dispose); a 2 px bar while pages still come. Tab text: Completed /
  បានបញ្ចប់ / 已完结.
- Tests: Next link detection, paging (stops at the last page, dedupe),
  failing later/first page, merge across sites with one failing, all
  failing; widget test of the tab (skeleton, first page, bar, second page,
  no reload when coming back). An old test now looks for the "Completed"
  status inside the grid (the tab has the same word). 267 passed.
- Found while testing: `StreamController.close()` must not be awaited (or
  put in tearDown) in a widget test; it waited for ever.
- Live check 2026-11-10 (temporary test, not committed): first list after
  1.4 s, all 624 after 10.1 s in 29 updates: AnimeXin 209, DonghuaWorld 217,
  DonghuaStream 112, LMAnime 71, LuciferDonghua 15.

## QA Results

Independent `qa-review` subagent, three rounds.

Round 1: Changes Requested. Round 2: Accepted, with two new Medium findings
that were fixed anyway. Round 3: **Accepted**, no new issue.

| Severity | Finding | Action |
| --- | --- | --- |
| High | H1: all sites failing showed "Nothing to show yet." (onDone replaced the error with an empty list) | Fixed: onDone keeps an error; widget test with Retry |
| Medium | M1: cancel waited for one site at a time, and the controller awaited it; a refresh hung and cancelled sites kept fetching | Fixed: all sites cancelled at once, not awaited by the controller |
| Medium | N1: a stalled site ended only when its request gave up (up to 25 s), not after `listingTimeout` | Fixed: no `cancelOnError`, a per-site `finished` flag, `onCancel` returns no future (it held back the done event); test (< 400 ms with a 50 ms timeout) |
| Medium | N2: a site whose first page failed after a cancel or timeout left an unhandled async error | Fixed: site cancels log their late errors; two tests (a test fails on an unhandled error) |
| Low | L2: an error after a partial list would wipe it | Fixed: the list stays; widget test |
| Low | L1 list reorders while pages arrive; L3 empty state has no Retry; L4 40-page cap only logs; some test gaps; one wall-clock test | Accepted (L1 by design, as in Popular) |

Round 3 checks: analyze clean, 272 tests passed (no hang), format clean.

## Notes and Limitations

- Not checked on the phone yet (not connected).
- The list reorders slightly while later pages arrive (merged by rank, like Popular).

## Git Commit

- Commit Message: `feat(explore): Completed tab with every completed series [TASK-036]`
- Commit Hash:
