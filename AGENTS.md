# DonghuaPlayer: Agent Guide

This file is the single source of truth for every AI coding agent working in this repository. Tool-specific files only point here.

## Overview

**DonghuaPlayer** (`donghua_player`) is a Flutter Android app for browsing and streaming donghua and anime. Content is scraped from AnimeXin (`animexin.dev`). There is no backend owned by this project.

## Technology stack

| Area | Technology |
| --- | --- |
| Language and framework | Dart, Flutter 3.38.8 (stable) |
| State management | `flutter_riverpod` |
| Networking and scraping | `dio`, `html` |
| Local storage | `hive`, `hive_flutter` |
| Playback | `flutter_vlc_player`, with `video_player` as fallback |
| Other | `wakelock_plus`, `screen_brightness`, `cached_network_image`, `intl` |
| Tests and lints | `flutter_test`, `flutter_lints` |
| Package manager | `pub` (`pubspec.yaml`, `pubspec.lock`) |

## Architecture

Dependencies flow `domain` → `data` → `features`. State lives in Riverpod providers.

```text
lib/
  main.dart                 App entry, ProviderScope, storage init
  core/                     Theme, debug logging (DLog), AppInfo
  core/l10n/                AppStrings: English and Khmer UI text
  core/widgets/             Shared widgets (skeleton placeholders, underline tab bar)
  domain/models/            Show, Episode, StreamSource, WatchHistoryItem,
                            ScheduleEntry
  domain/providers/         DonghuaStreamProvider contract
  data/providers/           AnimeXin scraper and listing parser,
                            StreamResolver, source filter
  data/storage/             Hive storage service
  features/                 One folder per area: splash, home, explore,
                            search, detail, player, library, settings
test/                       Widget, provider, and parser tests
  fixtures/                 Saved AnimeXin HTML for the parser tests
  support/                  Fakes shared by tests (fake stream provider)
android/                    Android host project
apk/                        Archived release APKs by ABI, not tracked by Git
                            (layout: apk/README.md)
team/                       Roles, task records, command playbooks
.githooks/                  Versioned Git hooks
```

## Setup

The Flutter SDK on the main development machine is `D:\DevTools\flutter` and is **not on PATH**. If `flutter` is not found, call `D:\DevTools\flutter\bin\flutter.bat` and `dart.bat` directly.

```bash
flutter pub get                       # ask first: downloads packages
git config core.hooksPath .githooks   # once per clone: enables the pre-commit hook
```

## Commands

| Purpose | Command |
| --- | --- |
| Run on a device | `flutter run` |
| Format changed files | `dart format <paths>` |
| Check formatting only | `dart format --output=none --set-exit-if-changed <paths>` |
| Lint | `flutter analyze --no-pub` |
| Test | `flutter test --no-pub` |
| Release build | `flutter build apk --release`, output in `build/app/outputs/flutter-apk/` |
| Smaller per-ABI build | `flutter build apk --release --split-per-abi`, one file per ABI in `build/app/outputs/flutter-apk/` |

Use `--no-pub` so a check never fetches packages by itself. On a fresh clone, run `flutter pub get` once, with approval.

Device setup and live testing, when the file is present locally: `FLUTTER_LIVE_TESTING.md`.

Release APKs kept for testing are archived in `apk/<abi>/`, ignored by Git; `apk/README.md` explains the layout and names. Do not rebuild, replace, or delete them unless asked.

## Coding standards

- Follow `flutter_lints` (`analysis_options.yaml`) and the default 80-column `dart format` style.
- New code follows `domain` → `data` → `features`. Screens do not call scrapers or storage directly.
- Keep changes small and on task. Do not refactor unrelated code or edit generated files.
- Add or update tests in `test/` when behavior changes.
- User-visible app text goes through `ref.watch(stringsProvider)` and an `S` key in `lib/core/l10n/app_strings.dart`, with both an English and a Khmer text. `test/app_strings_test.dart` fails when a key misses a language. Titles from the source are not translated.
- Change the `version:` line of `pubspec.yaml` and `AppInfo.version` / `AppInfo.buildNumber` in `lib/core/app_info.dart` together. `AppInfo.name` must equal `android:label` in `AndroidManifest.xml`. `test/app_info_test.dart` checks both.

## Naming conventions

| Item | Convention | Example |
| --- | --- | --- |
| Files | `snake_case.dart` | `player_controller.dart` |
| Types | `UpperCamelCase` | `HistoryNotifier` |
| Members | `lowerCamelCase` | `episodeStreamsProvider` |
| Providers | `<name>Provider` | `favoritesProvider` |
| Feature files | `<feature>_screen.dart`, `<feature>_controller.dart` | `search_screen.dart` |
| Branches | `<type>/<short-name>` | `fix/player-buffering` |

## Error handling

- Log failures with `DLog.error(tag, error, stack)` from `lib/core/debug_log.dart`, and events with `DLog.event(tag, data)`. `DLog` is enabled only in debug mode (`kDebugMode`).
- Surface loading and failure in the UI through `AsyncValue` state.
- Scraper and resolver code may treat one failed source as a skip, so other sources can still be tried. Do not add empty `catch` blocks anywhere else.
- Never log tokens, credentials, or signing data.

## Security

These rules bind every agent. Documentation is not a security boundary: also respect the permissions and restrictions of the tool you run in.

**Allowed without asking:** inspecting non-sensitive files; running tests, the analyzer, the formatter, and builds; reading Git status and diffs; editing files for the current task; creating normal local commits after a completed task.

**Ask first:** adding, removing, or upgrading packages (`flutter pub get/add/upgrade`, `npm install`, and similar); `git push`; deploying; destructive Git operations (`reset --hard`, force push, history rewrites); deleting important files or directories; changing infrastructure; any external action that affects users or services.

**Never:**

- Read, print, copy, or commit `.env*`, `*.pem`, `*.key`, `*.p12`, `*.pfx`, `*.jks`, `*.keystore`, SSH keys, `android/key.properties`, or anything under `secrets/`.
- Put secrets in code, logs, reports, documentation, or commits.
- Bypass a security restriction or skip a hook (`--no-verify`).
- Overwrite unrelated user changes, or commit them.

**Known issue:** `lib/main.dart` accepts all TLS certificates (`badCertificateCallback` returns `true`). Do not copy this pattern. Flag it whenever you touch networking.

## Git workflow

- `prod` is the default branch. Work on `<type>/<short-name>` branches.
- Inspect `git status` and `git diff` before every commit. Stage files by name; never use `git add -A` or `git add .`.
- One completed task, one local commit, in Conventional Commits form with the Task ID:

  ```text
  fix(player): resolve infinite buffering [TASK-013]
  ```

- Commit only after formatting, analysis, and tests pass. A failed check means no success commit.
- Commit after each task without asking. Never push without explicit approval.
- Do not rewrite existing history to split old commits.
- The commit hash cannot be inside its own commit. After committing, write the hash and `Status: Completed` to the task file, and include that edit in the next task's commit.

The pre-commit hook in `.githooks/` aborts a commit when a staged `.dart` file is unformatted or a staged path looks like a secret. It checks staged files only, so existing unformatted files do not block unrelated commits. Format a file when you change it, and do not mass-format the repository.

## Task management

Every non-trivial task gets one Task ID and one file in `team/Tasks/`. See `team/Tasks/README.md`.

- File name: `TASK-{NNN}-{short-kebab-description}.md`, for example `TASK-013-fix-player-buffering.md`.
- Take the next number after the highest existing one in `team/Tasks/`. Never reuse an ID or overwrite a task file.
- Start from `team/Tasks/task_template.md`.
- Status is one of `Pending`, `In Progress`, `In Review`, `Blocked`, `Completed`.
- `Completed` only after verification and the commit.

## Team responsibilities

| Role | Responsibility | Definition |
| --- | --- | --- |
| Advisor | Analyzes options and risks, recommends the simplest fit. Does not edit project files unless assigned. | `team/Advisor/README.md` |
| Dev | Implements the approved approach and runs checks. | `team/Dev/README.md` |
| QA Review | Independently verifies and reports findings by severity. | `team/QA Review/README.md` |
| Docs | Keeps documentation true to the implementation. | `team/Docs/README.md` |

Use real subagents when the tool supports them. Otherwise run the stages one after another, and record that QA was not independent. Never claim independent agents were used when they were not.

## Commands

Playbooks are tool-neutral and live in `team/Commands/`.

| Command | Purpose |
| --- | --- |
| `/task <description>` | Main entry point: runs the full workflow through commit |
| `/advisor <question or task>` | Technical planning and advice |
| `/dev <task-id or description>` | Implementation |
| `/qa-review <task-id>` | QA and code verification |
| `/doc <topic or task-id>` | Documentation updates |

## Tool support

| Tool | Instructions | Commands | Subagents |
| --- | --- | --- | --- |
| OpenCode | `AGENTS.md` | `.opencode/commands/` | `.opencode/agents/` |
| Claude Code | `CLAUDE.md`, which imports this file | `.claude/commands/` | `.claude/agents/` |
| Codex and others | `AGENTS.md` | None in the repo: follow `team/Commands/<name>.md` directly | Run stages in sequence if unsupported |

## Definition of Done

- [ ] Requirements understood, Task ID assigned, task file created.
- [ ] Implementation complete, follows conventions, no unrelated changes.
- [ ] `dart format` applied to changed Dart files.
- [ ] `flutter analyze --no-pub` passes.
- [ ] `flutter test --no-pub` passes.
- [ ] Build succeeds, when the change can affect it.
- [ ] QA Review complete and security reviewed.
- [ ] Documentation updated, when needed.
- [ ] Git diff reviewed; no secrets or unrelated files.
- [ ] Separate local commit created, hash recorded, status set to `Completed`.

If a check cannot be run, record why in the task file. Never fabricate results.

## Documentation

- Document only what exists and has been verified. State known limitations.
- Team documents, task files, and internal workflow files start with this header. Do not add it to source code, JSON, or manifests.

  ```markdown
  Author: [Author]
  Date: [YYYY-MM-DD]
  Task: [TASK-ID]
  ```

- Ask when requirements, scope, or a destructive action is unclear.
