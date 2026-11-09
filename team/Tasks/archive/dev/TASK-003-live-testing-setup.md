---
author: opencode
date: 2026-11-04
task: TASK-003
---

# Dev notes — live testing setup

## What was inspected first

- `flutter --version`, `flutter doctor -v`, `flutter devices`, `adb version`, `adb devices -l`
- Android SDK folders, JDK version, VS Code extension list
- scrcpy location and version

Result: Flutter, the SDK, the JDK, ADB, and the phone were all working. The phone appeared as `SM A546E` (`<device-id>`) in `device` state.

## Changes

- Installed VS Code extensions `Dart-Code.dart-code` and `Dart-Code.flutter` (3.146.0). This was the actual blocker for VS Code live testing.
- `.vscode/settings.json` — sets `dart.flutterSdkPath` to `D:\DevTools\flutter` because Flutter is not on PATH.
- `.vscode/launch.json` — adds the "DonghuaPlayer (Galaxy A54)" debug configuration with `deviceId: <device-id>`.
- `FLUTTER_LIVE_TESTING.md` — setup, device connection, run commands, hot reload, ADB troubleshooting, APK commands.

## Not changed

- Flutter SDK, Android SDK, USB driver, JDK, Gradle, and scrcpy were left as-is.
- No app code, feature, or dependency was changed.
- No emulator or Android Studio was started.

## Notes

- scrcpy is bundled with ScrcpyGUI at `C:\Users\AMSDev\AppData\Local\ScrcpyGUI\scrcpy-bin\scrcpy.exe`; it is not on PATH.
- The temporary UI text used for the Hot Reload proof was reverted.
- Tests and analyze were run after the revert.
