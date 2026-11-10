Author: AI Agent
Date: 2026-11-10
Task: TASK-025
Status: In Review

# TASK-025: Resolve the sources again when every server fails

## Objective

When every server of an episode has failed, fetch a fresh list of stream URLs
once by itself before showing the error, and make "Retry Stream" fetch fresh
URLs instead of trying the old ones again.

## Background

Owner, 2026-11-10: "Yes, add re-resolve", after the device test of v1.0.6
(TASK-024).

On the owner's network the public IP changed between runs (`srcIp` in the
OK.ru stream URLs went from `119.13.156.189` to `119.13.156.114`), which
looks like carrier-grade NAT. OK.ru binds its stream URLs to `srcIp`, and the
URLs also carry `expires`. The player resolved the sources once per episode
and only ever retried those URLs, so after an IP change or expiry every
server failed ("No server could play this episode") while the episode itself
was fine: a fresh resolve from the PC served it with 206.

## Requirements

1. When failover finds no server left, resolve the episode's sources again
   (`ref.invalidate(episodeStreamsProvider(...))`) once, without an error,
   keeping the position and the server the user picked by hand.
2. The automatic re-resolve is allowed again after a load plays, and on the
   next episode, so a long session still gets one after its URLs expire.
3. A second exhaustion in a row shows the error as before.
4. "Retry Stream" resolves the sources again (manual, no limit).
5. In the background nothing changes: `_failover` still defers there.

## Scope

`lib/features/player/player_screen.dart`,
`lib/features/player/source_selection.dart` (`kAutoReresolveLimit`,
`canAutoReresolve`), `test/source_selection_test.dart`.

## Out of Scope

Retrying single servers with fresh URLs while others are still left;
cross-source episode fallback.

## Assigned Roles

- Advisor: main agent
- Dev: main agent
- QA Review: `qa-review` subagent
- Docs: main agent

## Acceptance Criteria

- [x] Exhaustion triggers one automatic re-resolve, then the new list plays.
- [x] A second exhaustion shows the error.
- [x] Retry Stream re-resolves.
- [x] `dart format`, `flutter analyze --no-pub`, `flutter test --no-pub` pass (220).

## Device test

On the SM-A546E with a temporary debug-only change (not committed, removed
after the test, file restored from a copy) that replaced every URL with a
broken one until the first re-resolve:

```text
player.init src=2/4 ... engine=vlc url=https://ok.ru/zz-test-broken.mp4
player.engineFallback src=2 from=vlc to=exo
... all 4 servers fail on VLC and ExoPlayer ...
player.failover exhausted tried=4
player.reresolve ep=1 auto=1
streams.ready kept=5 ...
player.init src=3/5 server=Hardsub English Ok.ru 720p ... engine=vlc url=https://ok6-30.vkuser.net/...
```

The new list played on VLC (screenshot checked). Afterwards the archived
v1.0.6 APK was installed again so the phone has no test build.

## QA Results

Independent `qa-review` subagent: **Accepted** (no Critical or High).
analyze clean, 217 passed, format clean, no trace of the device hack. It
checked against the Riverpod 3.3.2 source that `when` passes the old list
during a refresh (`skipLoadingOnRefresh`), so no stale re-init or loop.

| Severity | Finding | Action |
| --- | --- | --- |
| Medium | M1: a re-resolve that finds nothing (offline) replaced the list with an empty one, so the player showed "No active streams" with only Go Back instead of Retry Stream | Fixed: `_reresolving`; an empty answer keeps the old list and shows `playerNoServer` with Retry Stream. A new list is only taken when the provider is not loading |
| Medium | M2: the counter reset on any "playing" report, so a stream that dies at the same point could re-resolve without end | Fixed: reset only after 10 s of real playback since the load first played (`hasRealProgress`), tests |
| Low | L1: a manual retry logged `auto=1` | Fixed: logs `manual` |
| Low | L2: spinner text names the old server during a re-resolve | Accepted (cosmetic) |
| Low | L3: no widget test of the flow (no PlayerScreen tests in the repo) | Accepted; helpers tested, flow device-tested |

After the fixes: 220 tests passed, and the device test with the temporary
hack was repeated (6 servers failed, one automatic re-resolve, the new list
played on VLC). The fixes were not re-reviewed by QA. The empty-answer
(offline) path was checked by code only: turning the phone offline would
change its settings.

## Documentation Updates

None needed: AGENTS.md describes the player at the level of engines and
failover, which still holds.

## Git Commit

- Commit Message: `feat(player): resolve sources again when every server fails [TASK-025]`
- Commit Hash:

## Final Report

## Notes and Limitations

- Not in any APK yet (v1.0.6 does not have it).
- The Retry button and the automatic path were device-tested only through the
  automatic path; the button calls the same `_reresolveSources()`.
