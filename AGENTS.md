# DonghuaPlayer — Agent Guide

## What this project is

- **DonghuaPlayer** (`donghua_player`) is a Flutter Android app for browsing and streaming donghua/anime.
- Content comes from **AnimeXin** (`animexin.dev`), scraped with `dio` + `html`.
- State management uses **Riverpod**. Local data (history, favorites, settings) uses **Hive**.
- Playback uses **flutter_vlc_player** with **video_player** as fallback.
- Extras: gesture controls for volume/brightness/seek, wakelock, cached posters.

## Project layout

```text
lib/
  main.dart                 App entry, ProviderScope, storage init
  core/theme/               App theme
  domain/models/            Show, Episode, StreamSource, HistoryItem
  domain/providers/         DonghuaStreamProvider contract
  data/providers/           AnimeXin scraper + StreamResolver
  data/storage/             Hive storage service
  features/
    home/ detail/ search/   Browse and search screens
    player/                 Player screen, controller, widgets
    library/ settings/      Saved shows and settings
test/                       Widget and provider tests
```

## How to run

```bash
flutter pub get          # ask first: downloads packages
flutter run              # debug run on a connected device/emulator
flutter build apk --release
```

Release APKs already exist in the repo root. Do not rebuild or replace them unless asked.

## How to test

```bash
flutter test             # unit + widget tests
flutter analyze          # static analysis
dart format <path>       # format changed Dart files
```

- Run tests after every behavior change.
- A change is done only when `flutter test` and `flutter analyze` pass.
- OpenCode auto-runs the Dart formatter after edits (`formatter: true`). If a file is still unformatted, run `dart format <file>` manually.

## Rules

1. **Format after every edit.** The Dart formatter must run on each changed `.dart` file.
2. **Tests are allowed.** Run `flutter test`, `flutter analyze`, and `dart format` without asking.
3. **Ask before `git push`.** Also ask before installing or updating packages (`flutter pub get`, `flutter pub add`, `npm install`, etc.).
4. **Never read secrets.** Do not read `.env*`, `*.pem`, `*.key`, `*.p12`, `*.pfx`, `*.jks`, `*.keystore`, SSH keys, `android/key.properties`, or anything under `secrets/`. These are denied in `opencode.jsonc`.
5. **Ask when unsure.** If requirements, scope, or a destructive action is unclear, ask before acting.
6. **Stay in scope.** Do not refactor unrelated code, rewrite generated files, or delete user work.
7. **Keep the architecture.** New code follows `domain` → `data` → `features`, with Riverpod providers for state.
8. **No secrets in code.** Never hardcode API keys, tokens, or signing credentials.

## Team workflow

Work is tracked in `.team/`:

- `.team/tasks/` — one file per task, based on `.team/tasks/_template.md`
- `.team/dev/` — implementation notes
- `.team/qa/` — test results
- `.team/review/` — code review findings
- `.team/advisor/` — risks, options, recommendations
- `.team/docs/` — documentation notes

Every file under `.team/` starts with this header:

```yaml
---
author: <name>
date: YYYY-MM-DD
task: TASK-000
---
```

Use the slash commands: `/task`, `/dev`, `/qa`, `/review`, `/advisor`, `/doc`.

## Known issues

- `lib/main.dart` accepts all TLS certificates (`badCertificateCallback` returns `true`). Do not copy this pattern into new code. Flag it when touching networking.

## Commands quick reference

| Command | Purpose |
| --- | --- |
| `/task <description>` | Create or update a task file |
| `/dev <task-id>` | Implement a task |
| `/qa <task-id>` | Test a task |
| `/review <task-id>` | Review changes |
| `/advisor <question>` | Get options and risks |
| `/doc <topic>` | Write or update docs |
