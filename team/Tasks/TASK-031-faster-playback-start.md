Author: AI Agent
Date: 2026-11-10
Task: TASK-031
Status: In Review

# TASK-031: Faster playback start, 720p to 4K

## Objective

Make an episode start sooner, also at high quality.

## Background

Owner `/task`, 2026-11-10: "Optimize Speed Play from 720p to 4K". Owner
chose all three: skip dead hosts, prefetch the next episode, adaptive start
for 2K/4K.

Measured on 2026-11-10 (PC, live): `streams()` of an AnimeXin episode took
7.4 s and 5.1 s before the player got a list. The resolver waits on hosts that
never yield a stream here: YouTube, Mega, Dood/playmogo, D.tube, Rumble (403).
OK.ru's HLS (Auto) stream is never added: the resolver reads
`hlsMasterPlaylistUrl`, the page has `hlsManifestUrl`.

## Requirements

1. Resolver returns at once for the dead hosts; shorter timeouts.
2. OK.ru HLS stream added (`hlsManifestUrl`, old key kept as fallback).
3. Prefetch the next episode's sources while the current one plays.
4. With 2K/4K chosen, start on the adaptive HLS stream of the preferred
   language when one exists; failover then goes to the fixed files.

## Acceptance Criteria

- [x] Measured resolve time before and after.
- [ ] Next episode starts from prefetched sources (device log). Open: phone not connected.
- [x] format, analyze, tests pass (246).

## Dev Results

- `kUnplayableHosts` / `isUnplayableHost` (by host, not path): YouTube,
  Mega, Drive, Dropbox, Dood family incl. playmogo, D.tube, Rumble, and the
  old list; the resolver answers them at once. Resolver timeouts 8 s → 6 s.
- Each embed URL is resolved once per page ("Primary Embed" repeated the
  menu's URL).
- OK.ru HLS: `hlsManifestUrl` read (old key kept). Every OK.ru episode now
  also has an "Auto HLS" stream.
- `StreamSourceFilter` keeps OK.ru CDN URLs (`vkuser.net`, `okcdn.ru`,
  `mycdn.me`, exact host or subdomain) without a probe: they come from
  OK.ru's fresh metadata, and probe timeouts had dropped working qualities
  (episode 1 kept 4-5 of 6). Dead ones are still caught by failover and
  the TASK-025 re-resolve.
- `isAdaptiveStream`; with 2K/4K chosen, `pickInitialSourceIndex` starts
  on the adaptive stream of the language group.
- Prefetch: from 60 % of an episode (or the last 3 minutes),
  `listenManual` keeps `episodeStreamsProvider(next)` alive; "Next" uses it
  without invalidating, and closes the listener after that frame.
- Measured (PC, live, `AnimeXinStreamProvider.streams()`, two episodes, two
  rounds, temporary test not committed):

  | Run | Before | After |
  | --- | --- | --- |
  | Episode 1, cold | 13.0 s, 6 qualities | 4.6 s, 6 + Auto HLS |
  | Episode 166 | 4.7 s | 3.2 s |
  | Episode 1, warm | 5.6 s | 3.1 s |
  | Episode 166 | 4.9 s | 3.2 s |

- Tests: unplayable hosts (incl. a host-only check), trusted hosts (no
  look-alikes), adaptive start (4K/2K, not for lower, language kept, single
  variant not adaptive), prefetch timing.

## QA Results

Independent `qa-review` subagent, two rounds (one review with TASK-033/034).

Round 1: Changes Requested (M1). Round 2: **Accepted**.

| Severity | Finding | Action |
| --- | --- | --- |
| Medium | M1: "Next" used the prefetched list even when it was empty (network gone during prefetch → "No streams" dead end) or old (expired / IP-bound URLs) | Fixed: `usePrefetched()` needs a non-empty list at most 20 min old, else resolve again as before; tests |
| Low | L7: dead-host check used substrings ("omega.io" matched "mega.io") | Fixed: host or subdomain match plus a Dood-family host rule; tests |
| Low | L8: with 2K/4K the adaptive stream wins even over a fixed 2160p file; ExoPlayer may cap by screen size | Owner's choice; to check on the phone |
| Low | A prefetch still running at "Next" is dropped and resolved again | Accepted (correct, a little slower) |

Round 2 checks: analyze clean, 261 tests passed, format clean, release build OK.

## Git Commit

- Commit Message: `perf(player): start playback faster [TASK-031]`
- Commit Hash:

## Notes and Limitations

- Not yet checked on the phone: "Next" from the prefetched list, and how high ExoPlayer climbs on the adaptive stream.
