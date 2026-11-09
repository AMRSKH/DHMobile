---
author: opencode
date: 2026-11-04
task: TASK-006
---

# TASK-006 — Development notes

## What landed
- Version bump: `pubspec.yaml` `1.0.3+4`, settings label `1.0.3 (Release)`.
- R8 + ProGuard for release (`isMinifyEnabled`, `isShrinkResources = true`, custom `android/app/proguard-rules.pro` keeps for Flutter/VLC/playback/Media codec/MethodChannel; Play Core missing-class rule added).
- New split-ABI builds reported by `flutter build apk --split-per-abi`:
  - `app-arm64-v8a-release.apk`: **61.4 MB** (-66.7% vs 184.5 MB)
  - `app-armeabi-v7a-release.apk`: 54.6 MB
  - `app-x86_64-release.apk`: 68.5 MB
- Unified single APK after R8: 180.7 MB.
- No `package` rename involved; MethodChannel `dev.amscenter.donghua_player/volume` unchanged.

## Validation
- `flutter analyze`: no issues.
- `flutter test`: 12/12 pass.
- Side-loaded `app-arm64-v8a-release.apk` on SM A546E; new app id `dhmobile.amscenter.dev` installed fresh; Settings shows v1.0.3; launcher is on device.

## Notes
- `flutter_native_splash` still not installed; splash remains platform-default white with AMSCenter credits on the Flutter launch router.
- If the user wants split APKs by default when running `flutter build apk --release`, Gradle splits are not enabled in `build.gradle.kts`. Rerun `--split-per-abi` manually.
