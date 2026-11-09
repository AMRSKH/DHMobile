---
author: opencode
date: 2026-11-04
task: TASK-003
---

# QA report — live testing on the physical device

## Root cause

- The phone, ADB, and Flutter were already working. `adb devices -l` and `flutter devices` listed `SM A546E` (`<device-id>`) as `device`.
- VS Code had **no Dart or Flutter extension** installed, so F5, the device selector, Hot Reload buttons, and the debug console were unavailable.
- `flutter` and `dart` are not on PATH, so VS Code needed an explicit SDK path.
- scrcpy was present but only as a bundled binary inside ScrcpyGUI, not on PATH.

## Environment (verified)

| Item | Result |
| --- | --- |
| Flutter | 3.38.8 stable, `D:\DevTools\flutter` |
| Dart | 3.10.7 |
| Android SDK | `C:\Users\AMSDev\AppData\Local\Android\Sdk`, platform android-36, build-tools 35.0.0 |
| JDK | Microsoft JDK 21 |
| ADB | 1.0.41 (37.0.1) |
| Device | SM A546E, Android 17 (API 37), `<device-id>` |
| scrcpy | 5.0.1, `C:\Users\AMSDev\AppData\Local\ScrcpyGUI\scrcpy-bin\scrcpy.exe` |

## Changes made

- Installed VS Code extensions `Dart-Code.dart-code` 3.146.0 and `Dart-Code.flutter` 3.146.0.
- Added `.vscode/settings.json` with `dart.flutterSdkPath`.
- Added `.vscode/launch.json` with a "DonghuaPlayer (Galaxy A54)" debug config.
- Added `FLUTTER_LIVE_TESTING.md`.
- No SDK, driver, or app code was changed.

## Verification

| Command / test | Result |
| --- | --- |
| `adb devices -l` | Pass — `<device-id>  device` |
| `flutter devices` | Pass — SM A546E listed |
| `flutter run -d <device-id> --no-resident` | Pass — built, installed, launched |
| `flutter run -d <device-id>` | Pass — attached, synced files |
| Hot Reload (`r`) | Pass — `Reloaded 1 of 2290 libraries in 1,516ms` |
| Hot Restart (`R`) | Pass — `Restarted application` |
| scrcpy | Pass — server pushed, window ran 10 s |
| `adb devices -l` after scrcpy | Pass — still `device` |
| Emulator/Android Studio processes | Pass — none running |
| `flutter analyze` | Pass — no issues |
| `flutter test` | Pass — 12 tests |
| Temporary UI change | Pass — reverted |

## Bugs found

None. No code defect was found in this task.

## Not verified

- VS Code breakpoint hit and the Debug Console inside the IDE. The extensions and launch config are in place, but this needs one manual F5 run.
