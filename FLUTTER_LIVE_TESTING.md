# Flutter Live Testing (Windows + Galaxy A54)

Verified on 2026-11-04 with Flutter 3.38.8 and a Samsung SM-A546E (Galaxy A54 5G).

## Environment

| Item | Value |
| --- | --- |
| Flutter SDK | `D:\DevTools\flutter` (not on PATH) |
| Dart | `D:\DevTools\flutter\bin\dart.bat` |
| Android SDK | `C:\Users\AMSDev\AppData\Local\Android\Sdk` |
| ADB | `C:\Users\AMSDev\AppData\Local\Microsoft\WinGet\Packages\Google.PlatformTools_...\platform-tools\adb.exe` |
| JDK | Microsoft JDK 21 (`JAVA_HOME`) |
| Device | SM A546E, serial `<device-id>` (from `flutter devices`) |
| scrcpy | `C:\Users\AMSDev\AppData\Local\ScrcpyGUI\scrcpy-bin\scrcpy.exe` (5.0.1) |

## 1. Initial setup

1. Install the VS Code extensions **Dart** and **Flutter** (`Dart-Code.dart-code`, `Dart-Code.flutter`). Without them F5 and the device selector do nothing.
2. `.vscode/settings.json` points VS Code at the SDK:

   ```json
   { "dart.flutterSdkPath": "D:\\DevTools\\flutter" }
   ```

3. Optional, to use `flutter` in any terminal:

   ```powershell
   setx PATH "$env:PATH;D:\DevTools\flutter\bin"
   ```

   Restart the terminal afterwards.

## 2. Connect the phone

1. On the phone: Settings → About phone → tap **Build number** 7 times.
2. Settings → Developer options → enable **USB debugging**.
3. Plug in USB, choose **File transfer** mode, and accept the **Allow USB debugging** prompt.
4. Check the connection:

   ```powershell
   adb devices -l
   flutter devices
   ```

   The phone must show `device`, not `unauthorized` or `offline`.

## 3. Start live testing

In VS Code:

1. Pick the device in the status bar, or run **Flutter: Select Device**.
2. Press **F5** (or Run → Start Debugging).
3. The app installs and launches on the phone; logs appear in the Debug Console.

From a terminal:

```powershell
D:\DevTools\flutter\bin\flutter.bat run -d <device-id>
```

This machine also has a local launch config: `.vscode/launch.json` → "DonghuaPlayer (Galaxy A54)". It is gitignored because it holds the device serial.

## 4. Hot Reload and Hot Restart

| Action | VS Code | Terminal |
| --- | --- | --- |
| Hot Reload | save the file, or the reload button | `r` |
| Hot Restart | restart button | `R` |
| Quit | stop button | `q` |

Hot Reload keeps app state; use Hot Restart after changing global state, `main()`, or native code.

## 5. scrcpy mirroring

```powershell
& "C:\Users\AMSDev\AppData\Local\ScrcpyGUI\scrcpy-bin\scrcpy.exe" --no-audio --max-size=1024
```

scrcpy and Flutter share the same ADB connection. If install or launch fails, close scrcpy and retry.

## 6. Common ADB troubleshooting

| Symptom | Fix |
| --- | --- |
| `unauthorized` | On the phone: Developer options → Revoke USB debugging authorizations, replug, accept the prompt. |
| `offline` or no device | Replug the cable, try another USB port (prefer USB 3 directly on the PC). |
| Device not listed at all | Check Device Manager for an unknown device; install the Samsung USB driver. |
| `adb server version doesn't match` | `adb kill-server` then `adb start-server`. |
| Port 5037 busy | `netstat -ano | findstr :5037`, stop the owning process, restart the server. |
| Phone only charges | Set USB mode to File transfer and enable USB debugging again. |
| Flutter does not see the device | `flutter devices --device-timeout 60` |

## 7. APK build commands

```powershell
D:\DevTools\flutter\bin\flutter.bat build apk --debug
D:\DevTools\flutter\bin\flutter.bat build apk --release
D:\DevTools\flutter\bin\flutter.bat build apk --release --split-per-abi
```

Output: `build\app\outputs\flutter-apk\`.

APKs kept for testing are copied from there into `apk\<abi>\` (one folder per ABI) and renamed `DHMobile-<version>[-<variant>]-<abi>.apk`. See `apk/README.md` for the layout and the name of each file.

## 8. Resource notes

- No emulator and no Android Studio are needed; both are slow on this machine.
- Keep one IDE open and stop unused Gradle daemons with `gradlew --stop` if memory is tight.
- Use `--no-resident` for a quick install-and-launch without attaching the debugger.
