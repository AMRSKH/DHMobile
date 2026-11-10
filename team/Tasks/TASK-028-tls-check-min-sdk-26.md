Author: AI Agent
Date: 2026-11-10
Task: TASK-028
Status: In Review

# TASK-028: Check TLS certificates, raise minSdk to 26

## Objective

Remove the accept-all TLS callback from `lib/main.dart` and require Android 8
(API 26), whose trust store covers the certificate chains of the sources.

## Background

Owner decision, 2026-11-10 ("Remove + Android 8+ (Recommended)"). Known issue
since TASK-001: `_AppHttpOverrides.badCertificateCallback` returned `true` for
every host, so any network could read or change the app's traffic (MITM). It
came in with `d98afc4` ("resolve OK.ru ..."), probably for an older test
device.

Chains checked on 2026-11-10: AnimeXin, DonghuaWorld, LuciferDonghua,
DonghuaStream, Dailymotion CDN: Google Trust Services; LMAnime: Let's Encrypt
YR2 → Root YR → ISRG Root X1; OK.ru: HARICA DV TLS RSA → HARICA TLS RSA Root
CA 2021 → Hellenic Academic RootCA 2015; www.dailymotion.com: Amazon.

## Requirements

1. `HttpOverrides` and the callback removed; no accept-all callback anywhere.
2. `minSdk = 26` in `android/app/build.gradle.kts`, with the reason.
3. All sources, posters, and OK.ru playback still work on the device.
4. AGENTS.md: the known-issue note replaced by the rule.

## Scope

`lib/main.dart`, `android/app/build.gradle.kts`, `AGENTS.md`.

## Acceptance Criteria

- [x] No `badCertificateCallback` or `HttpOverrides` in `lib/`.
- [x] `minSdk=26` (`dumpsys package` on the phone after install).
- [x] Device, v1.0.8 release: Explore loads; search "renegade immortal" returns cards from all five sources (AnimeXin 2, DonghuaStream 2, LuciferDonghua 2, DonghuaWorld 1, LMAnime 1); posters show; OK.ru plays; no `HandshakeException` / `CERTIFICATE_VERIFY_FAILED` in logcat.
- [x] format, analyze, tests pass (220).

## QA Results

Independent `qa-review` subagent (one review with TASK-027): **Accepted**.
No accept-all callback, `HttpOverrides`, custom trust manager, or hostname
verifier left in `lib/` or `android/`; `lib/` no longer imports `dart:io`.
No dependency needs a minSdk above 26 (`flutter_vlc_player` 21,
`video_player_android` 24, others lower).

| Severity | Finding | Action |
| --- | --- | --- |
| Low | `AndroidManifest.xml` keeps `android:usesCleartextTraffic="true"`, so plain `http://` streams stay unprotected | Out of scope; recorded in Notes as a follow-up |
| Low | Android 8 trust of HARICA 2015 / ISRG X1 not verified on API 26-28 | Already in Notes; a missing root now fails with a certificate error, not silently |
| Low | AGENTS.md holds edits of TASK-027 and TASK-028 | Staged per task |

## Git Commit

- Commit Message: `fix(security): check TLS certificates and require Android 8 [TASK-028]`
- Commit Hash:

## Notes and Limitations

- `android:usesCleartextTraffic="true"` is still set (plain HTTP allowed for
  the native players). Check which stream hosts still use `http://` before
  turning it off; a separate task.

- Android 7.x phones can no longer install new versions.
- Tested on Android 17 only. That Android 8 trusts every chain above was not
  tested on a device; HARICA RootCA 2015 and ISRG Root X1 are in the Android
  trust store from Android 7.1.1 / 8, as far as known (not verified here).
