---
author: opencode
date: 2026-11-04
task: TASK-006
---

# TASK-006 — Build a smaller v1.0.3 APK

## Status
- [x] Planned
- [x] In progress
- [x] QA
- [x] Review
- [x] Done

## Goal
Ship a new release build labeled v1.0.3 that is meaningfully smaller than the current ~184 MB release APK ( dominated by `libvlc-all` native libraries ), while preserving full playback features and the recent renames/TASK-005 improvements.

## Scope

**In scope**
- Bump `pubspec.yaml` version to `1.0.3+1` (or `+4` continuing) and in-app label on `settings_screen.dart`.
- Audit APK size drivers (lib/arm64-v8a/libvlc*, resources, assets) with `flutter build apk --analyze-size` saved JSON; report per-component bytes.
- Configure Gradle `ndk.abiFilters` to `arm64-v8a` only for the release profile (drop armeabi-v7a/x86/x86_64) once confirmed no emulator testing is needed, or keep all ABIs behind product flavors.
- Split APKs (`flutter build apk --split-per-abi`) so end users receive a per-architecture APK (~-70% size).
- R8 / ProGuard shrink and obfuscation for Java/Kotlin after QA (`isMinifyEnabled = true`, `proguard-rules.pro`), preserving `io.flutter.**`, `org.videolan.**`, `dev.amscenter.donghua_player.**`.
- Disable unused build features: `isShrinkResources = true` (requires resources keep list), remove unused assets from `flutter: assets:` list.
- Compress PNG posters via 9-patch/webp conversion where applicable; remove any embedded test fixtures.
- Verify output APK size vs current 184.5 MB.

**Out of scope**
- Dropping VLC (playback core dependency).
- Uploading to a store / code signing.
- Reducing video quality (network, not APK).

## Acceptance criteria
- [ ] `flutter build apk --release` (or split variant) produces an APK at the same or new path, and its size is reported in release notes.
- [ ] Single-ABI APK size is at least 40% smaller than 184.5 MB (per-arch ABI).
- [ ] `flutter test` 12/12 still passes.
- [ ] `flutter analyze` clean.
- [ ] MethodChannel `dhmobile.amscenter.dev/volume` (or legacy channel) still answers volume on-device after the NDK/shrink change (regression test on the A54).
- [ ] Playback smoke (play + seek + next episode) passes on device.

## Plan
1. Run `flutter build apk --release --analyze-size` and save the JSON to `.team/qa/...`.
2. Enable `flutter build apk --split-per-abi` first (no code risk) and confirm ~95 MB per ABI.
3. Set ABI filters and measure.
4. Enable R8 + shrinkRes aggressively, fix any missing-keep rules by checking runtime crash/`Missing` logcat.
5. Audit `pubspec.yaml` assets; trim.
6. Run format/analyze/test; build; side-load on A54; smoke test gestures/playback.
7. Write report + QA notes in `.team/`.

## Risks
- R8 minification can break plugin reflection (flutter_vlc_player) → set explicit keeps.
- Dropping non-arm ABIs kills emulator/x86 CI testing — only do release variant, keep default debug multi-arch.
- Shrinking resources might remove `ic_launcher` references; test launcher icon.
- Changes may affect the native volume channel if Kotlin classes obfuscated without keeps.

## Notes
- User-facing ask: "new build v1.0.3 apk file. normal i see it too large can make it smaller" (2026-11-04).
- Existing repo-root APKs are gitignored; do not replace them unless explicitly asked. The new build lands in `build/app/outputs/flutter-apk/`.
