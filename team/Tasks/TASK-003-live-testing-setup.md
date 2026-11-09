---
author: opencode
date: 2026-11-04
task: TASK-003
---

# Live testing on the physical Android device

## Status

- [x] Planned
- [x] In progress
- [x] QA
- [x] Review
- [ ] Done

## Goal

The app runs live on the Samsung Galaxy A54 5G from VS Code: the device is detected by ADB and Flutter, `flutter run -d <device-id>` launches it, Hot Reload and Hot Restart work, the debug console and breakpoints work, and scrcpy mirrors the phone. No emulator and no Android Studio are used.

> Note: the request title says "Emulator", but the requirements say physical device and "do not launch Android Emulator". This task follows the physical-device path.

## Scope

**In scope**

- Inspect the current environment without changing it:
  - `flutter doctor -v`, `flutter --version`, `flutter devices`, `flutter emulators`
  - `adb version`, `adb devices -l`
  - Android SDK path, platform-tools, build-tools, command-line tools
  - Java and Gradle compatibility
  - VS Code Dart and Flutter extensions
- Fix USB detection for the Galaxy A54 5G:
  - Developer Options and USB debugging
  - RSA authorization prompt on the phone
  - Samsung or Google USB driver on Windows
  - ADB server restart and port conflicts
- Configure VS Code live debugging for the physical device:
  - device selection, F5, breakpoints, debug console
  - Hot Reload and Hot Restart
- Verify scrcpy works alongside ADB without conflicting.
- Run one real end-to-end test on the phone, including a temporary UI-only change to prove Hot Reload.
- Write `FLUTTER_LIVE_TESTING.md` with the setup, commands, and troubleshooting.

**Out of scope**

- Reinstalling Flutter, the Android SDK, scrcpy, or VS Code extensions that already work.
- Android Studio and Android Emulator.
- Changing app features, business logic, or dependencies.
- Fixing the TLS bypass or other audit items from TASK-001.

## Acceptance criteria

- [x] `adb devices -l` lists the Galaxy A54 5G as `device` (not `unauthorized` or `offline`).
- [x] `flutter devices` lists the phone.
- [x] `flutter run -d <device-id>` installs and launches the app on the phone.
- [x] Hot Reload updates a temporary UI change without a full restart.
- [x] Hot Restart works.
- [ ] VS Code shows app logs in the debug console and stops on a breakpoint. (Extensions installed and configured; breakpoint check is a manual VS Code step.)
- [x] `scrcpy` mirrors the phone while ADB stays connected.
- [x] No emulator and no Android Studio process is started.
- [x] `FLUTTER_LIVE_TESTING.md` exists and matches the verified commands.
- [x] The temporary UI change is reverted and `flutter analyze` still passes.

## Plan

1. Record the current environment: run the inspection commands and save the output.
2. Compare results against the expected device state and identify the exact failure point (driver, authorization, ADB server, or VS Code).
3. Fix only the failing layer:
   - enable Developer Options and USB debugging on the phone,
   - accept the RSA fingerprint prompt,
   - install the matching USB driver if Windows does not enumerate the device,
   - restart the ADB server and re-check.
4. Confirm the device in `flutter devices`, then run `flutter run -d <device-id>`.
5. Verify Hot Reload, Hot Restart, console logs, and one breakpoint.
6. Start scrcpy and confirm ADB still reports the device.
7. Write `FLUTTER_LIVE_TESTING.md` with the verified steps.
8. Revert the temporary UI change, run `dart format`, `flutter analyze`, and `flutter test`.

## Risks

- **Windows driver issues block detection.** Mitigation: check Device Manager for an unknown or ADB-interface device before installing anything.
- **Phone shows `unauthorized`.** Mitigation: revoke USB debugging authorizations on the phone, replug, and accept the new prompt.
- **Another process holds ADB port 5037.** Mitigation: find the owner, close it, and restart the ADB server.
- **Samsung USB mode defaults to charging only.** Mitigation: set USB mode to File Transfer or USB debugging on the phone.
- **scrcpy and Flutter both fight for the device.** Mitigation: start scrcpy after `flutter run`, and close it if install or launch fails.
- **Machine is resource-limited (i5 8th gen, 16 GB).** Mitigation: keep one IDE open, no emulator, and stop unused Gradle daemons.
- **Temporary UI change is left in the tree.** Mitigation: revert it and verify with `git status` before finishing.

## Notes

- Flutter is not on PATH. Use `D:\DevTools\flutter\bin\flutter.bat` and `D:\DevTools\flutter\bin\dart.bat`.
- scrcpy is already installed; locate it before use.
- Results and any manual phone steps go in `.team/qa/TASK-003-live-testing-setup.md`.
- Deliverables: root cause, changes made, verification results, exact commands, remaining issues.
