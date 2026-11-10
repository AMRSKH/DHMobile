Author: AI Agent
Date: 2026-11-10
Task: TASK-015
Status: Blocked

# TASK-015: Netflix-style splash, source schedule, skeletons, About, display language

## Objective

Finish the open device retest of TASK-014, then deliver five UI changes the owner asked for: one Netflix-style splash, Explore lists that come from the source's schedule with "New Series" and "Popular" categories, skeleton loading, a corrected About section, and a display language option (Khmer and English).

## Background

Owner request, 2026-11-10:

> Continue not complete work then Update Splash Screen To The same style as NETFLIX and it has only one no duble splash screen and Each Day List All Those day movie listed from source by add new series and popular category. Add Skeleton instead of normal loading screen. and Update Setting too at About. Add Display Language Option to Setting Too. it has KH - ភាសាខ្មែរ and EN - English

State before the task (commit `d16c814`):

- Startup shows two screens: the Android launch window (white in light mode, the system splash with the app icon on Android 12 and later), then a white Flutter `SplashScreen` with black text for a fixed 2 s.
- Explore day lists are 7 titles from a seeded shuffle of homepage episode posts, not a schedule (TASK-014 observation). `show.id` is an episode post URL.
- Loading states use `CircularProgressIndicator`.
- Settings About is hardcoded: "DonghuaPlayer", "Version 1.0.3 (Release)", "Built with Flutter & libVLC". The player in use is `video_player`.
- All UI text is hardcoded English.

Source pages checked on 2026-11-10 with the app's user agent (HTTP 200 each):

| Page | Content |
| --- | --- |
| `/schedule/` | Seven blocks `div.bixbox.schedulepage.sch_<weekday>`, each with `.bsx` items: series URL, title, poster, `.epx` (release time or "released"), `.sb` (episode number or "??"). 61 items in total, 6 to 14 per day |
| `/anime/?order=popular` | 30 `article.bs` items with series URLs, `.epx` status |
| `/anime/?order=latest` | 30 `article.bs` items with series URLs, newest added first |

`episodes(showId)` already reads `.eplister` from a series URL.

## Requirements

1. Continue the incomplete work of TASK-014: install the last build and retest the L1, L2, and L4 edits on the device.
2. Splash: Netflix style, and only one splash is visible at startup.
3. Explore: each day lists all shows of that day from the source. Add the categories "New Series" and "Popular".
4. Skeleton placeholders replace the normal loading indicator on content screens.
5. Settings About is updated and correct.
6. Settings has a "Display Language" option with "KH - ភាសាខ្មែរ" and "EN - English".

Assumptions made by the main agent, since the request leaves them open:

- "Netflix style" means the look and motion: black background, red logo that zooms in, then a fade into the app. No Netflix name, logo, or sound is used.
- "Only one splash" means the Android launch window is plain black without an icon, so the Flutter animation is the only splash the user sees.
- Explore gets three categories: the weekly schedule (with the day selector), "New Series", and "Popular". "New Series" is the source's newest added series, "Popular" is the source's popular order.
- The app name shown in the app is "DHMobile", the label the owner set in `AndroidManifest.xml`.
- The display language changes the app's own text. Titles and episode names from the source stay as the source writes them. The default is English.
- Skeletons replace the loading indicator of content lists (Explore, Detail episodes, Search results) and image placeholders. The buffering indicators inside the video player stay.

## Scope

- `lib/features/splash/`, Android launch theme resources under `android/app/src/main/res/`.
- `lib/features/explore/`, `lib/data/providers/animexin_stream_provider.dart`, `lib/domain/providers/stream_provider.dart`.
- A shared skeleton widget, used in Explore, Detail, and Search.
- `lib/features/settings/`, `lib/data/storage/storage_service.dart` (language key).
- A strings layer for English and Khmer, used by the screens.
- Tests for the new parsing, the strings, the settings, and the version constant.
- `team/Tasks/TASK-014-live-test-find-and-fix.md` (retest results).

## Out of Scope

- New packages. Nothing is added to `pubspec.yaml` dependencies.
- The player logic of TASK-014.
- F2 (Search entry in the UI), the meaning of Quality "Auto", F11, and the other deferred items of TASK-014. They wait for the owner.
- Translating content from the source.
- iOS launch screen.

## Assigned Roles

- Advisor: `advisor` subagent.
- Dev: `dev` subagent.
- QA Review: `qa-review` subagent.
- Docs: `docs` subagent.

## Implementation Plan

From the advisor, accepted by the main agent:

1. `AppInfo`, the About rows, `app_info_test`.
2. The strings layer, the storage key, settings, the Display Language option, and their tests.
3. `ScheduleEntry`, the parsers, the provider API, fixtures, parser and provider tests. Remove the shuffle.
4. `skeleton.dart` and its test.
5. Explore controller and screen, with tests.
6. Skeletons in Detail, Search, and the image placeholders.
7. Splash widget and Android resources. Rewrite `widget_test.dart`.
8. Move the strings of the remaining screens. `player_controls.dart` last.
9. Format, analyze, test, debug APK, device check.

## Dependencies

The live AnimeXin site and a connected, unlocked device for the live check.

## Acceptance Criteria

- [x] The L1, L2, and L4 retest of TASK-014 was run on the device and recorded.
- [ ] Startup shows one splash: black launch window, then the red logo animation, then Explore. No white frame and no system icon splash. Device: passed in dark mode, light mode not tested.
- [x] Each weekday in Explore lists every show the source's schedule has for that day.
- [x] Explore has "New Series" and "Popular" categories filled from the source.
- [ ] A show opened from Explore loads its episode list and plays. Device: not tested, episode load covered by tests.
- [ ] Explore, Detail episodes, and Search show skeletons while loading. Explore seen on the device, Detail and Search by tests only.
- [x] About shows the app name, the version of `pubspec.yaml`, and the player actually in use.
- [ ] Settings has Display Language with "KH - ភាសាខ្មែរ" and "EN - English". The choice changes the app text at once and survives a restart. Switch seen on the device, restart on Hive not tested.
- [x] `flutter analyze --no-pub` passes.
- [x] `flutter test --no-pub` passes.
- [x] A debug APK builds.

## Testing Requirements

- Unit tests: schedule and listing parsers on saved HTML fixtures, strings (every key has both languages), settings language persistence, version constant equals `pubspec.yaml`.
- Widget tests: skeleton shown while loading, Explore category and day selection, Settings language option.
- Live check on the device: startup, each Explore category, one day list compared with the source page, open a show and play, language switch, restart.

## TASK-014 Retest

Run on 2026-11-10 with the build of commit `d16c814`. Details are in the TASK-014 record under "Device retest after the commit".

| Case | Result |
| --- | --- |
| L2 | Pass |
| L1 | Pass for the result. The buffering timing of the pick is not confirmed |
| L4 | Partly covered. The re-arm branch did not occur |

## Advisor Recommendation

By the `advisor` subagent, from reading the code and the saved source pages. Nothing was run or built. Condensed by the main agent.

Two points for the owner:

- The Netflix look means the credit lines leave the splash. They stay in Settings, About.
- "New Series" from the source includes "Upcoming" titles, which have no episodes yet.

### 1. Splash

Flutter, `lib/features/splash/splash_screen.dart` as a `ConsumerStatefulWidget`:

| Item | Decision |
| --- | --- |
| Look | Black `Scaffold`. Centered `Text(AppInfo.name)` in `AppTheme.primaryRed`, `FontWeight.w900`, size about 46, `TextScaler.noScaling`. No asset, no credit lines |
| Motion | One `AnimationController`, 2000 ms, no `Timer` |
| 0 to 30% | Opacity 0 to 1, scale 0.80 to 1.00 (easeOutCubic) |
| 30 to 70% | Scale 1.00 to 1.08 |
| 70 to 100% | Scale 1.08 to about 8 (easeInCubic), opacity to 0 over the last 15% |
| Handover | On `AnimationStatus.completed`: `pushReplacement` to `MainScreen` with a 350 ms `FadeTransition` |
| Warm-up | `ref.read(exploreControllerProvider)` in `initState` starts the schedule request. The splash does not wait for the network |

Android resources:

| File | Change |
| --- | --- |
| `values/styles.xml` | `LaunchTheme` and `NormalTheme` get parent `@android:style/Theme.Black.NoTitleBar`. `LaunchTheme` keeps `windowBackground` `@drawable/launch_background`. `NormalTheme` gets `windowBackground` `@android:color/black` |
| `values-night/styles.xml` | Delete. The night qualifier outranks the API-level qualifier, so in dark mode it would hide `values-v31` and bring the icon splash back |
| `values-v31/styles.xml` | New, `LaunchTheme` only: `windowBackground` `@drawable/launch_background`, `android:windowSplashScreenBackground` `@android:color/black`, `android:windowSplashScreenAnimatedIcon` `@drawable/splash_no_icon` |
| `drawable/launch_background.xml`, `drawable-v21/launch_background.xml` | `<item android:drawable="@android:color/black" />` |
| `drawable/splash_no_icon.xml` | New transparent `<shape>` |
| `AndroidManifest.xml`, `MainActivity.kt` | No change |

Not sure on Android 12 and later: the system splash cannot be turned off, a transparent icon on black is the usual way to hide it, not verified on Android 17 or One UI. If an icon still shows, try `@android:color/transparent` as the icon value. If a flash shows at the handover, remove the splash view in `MainActivity` with `splashScreen.setOnExitAnimationListener` (platform API). A debug build starts slowly, so black lasts longer there.

### 2. Source data

Contract in `lib/domain/providers/stream_provider.dart`, `weekday` is dropped:

```dart
Future<List<Show>> search(String query);
Future<Map<int, List<ScheduleEntry>>> schedule(); // keys 1 (Mon) to 7 (Sun), all present
Future<List<Show>> newSeries();
Future<List<Show>> popular();
```

- New model `lib/domain/models/schedule_entry.dart`: `ScheduleEntry { Show show; bool released; DateTime? releaseAt; String? releaseText; }`. Release data stays out of `Show`, because `Show` is saved with favorites and history.
- New `lib/data/providers/animexin_listing_parser.dart` with pure functions `parseSchedule(String html, {required String providerId})` and `parseSeriesList(String html, {required String providerId})`.

| Page | Request | Selectors |
| --- | --- | --- |
| Schedule | `GET /schedule/` | Blocks `div.schedulepage`, weekday from the `sch_<name>` class token (the page does not start at Monday). Items `.bsx` in the block: `a[href]`, `a[title]` (fallback `.tt`), `img` `data-src` then `src`, `.epx` text, `.epx[data-rlsdt]`, `.sb` text |
| Popular | `GET /anime/?order=popular` | `.listupd article.bs`: `.bsx a[href]`, `a[title]` (fallback `.tt h2`), `img src`, `.epx` |
| New Series | `GET /anime/?order=latest` | Same parser |

| Field | Schedule item | Listing item |
| --- | --- | --- |
| `Show.id` | Series URL | Series URL |
| `Show.title` | Link title, without `cleanShowTitle` | Link title |
| `Show.episodeCount` | `'EP <n>'` when `.sb` is a number, else null | null |
| `Show.status` | null | `.epx` text (Ongoing, Completed, Upcoming) |
| `released` | `.epx` text is "released" | n/a |
| `releaseAt` | `data-rlsdt` (epoch seconds, UTC) when not empty | n/a |
| `releaseText` | Raw `.epx` text, for example "at 12:02" | n/a |

- The release time never goes into `episodeCount`: Detail shows that field as a badge and favorites store it.
- Skip an item with an empty URL or title. Dedupe by URL inside one day or list. A `data:` image `src` counts as empty.
- The "at HH:mm" text of the page is UTC. The card shows local time from `releaseAt`. Without `releaseAt` it shows the raw text.
- Not sure whether `.sb` is the next or the latest episode number.
- `search('')` returns `popular()`. `_scrapeWeekdayTrending`, `_cachedWeekdayTrending`, the trending cache fields, and the `dart:math` import go. `search(query)` stays, with its fallback list. `cleanShowTitle` loses its last caller, it stays with its test.
- No cache in the data layer. The controller keeps the schedule for the session, Refresh fetches again.
- The three new methods do not catch and never return the built-in list. Zero items in total throws `FormatException`, and the UI shows an error with Retry. A single empty day is valid.
- Only the first page (30) of New Series and Popular is loaded.
- Security note: `lib/main.dart` accepts every TLS certificate and the manifest allows cleartext. Older state, not changed here.

### 3. Explore UI

- AppBar: title and Refresh, which calls `controller.refresh()`.
- Row 1: three `ChoiceChip`s (Schedule, New Series, Popular). Row 2, only for Schedule: the day selector. A day change needs no network.
- Body: the two-column grid. Caption: Schedule shows `EP 47 · 10:50` or `EP 564 · Released`, lists show `show.status`.
- Default: Schedule and today.
- Loading shows `SkeletonPosterGrid`. An error shows a localized message with Retry, the raw error goes to `DLog` only. An empty day shows its own text.

```dart
enum ExploreCategory { schedule, newSeries, popular }
class ExploreState {
  final ExploreCategory category;
  final int weekday; // 1..7
  final AsyncValue<Map<int, List<ScheduleEntry>>> schedule;
  final AsyncValue<List<Show>> newSeries;
  final AsyncValue<List<Show>> popular;
}
// ExploreController extends Notifier<ExploreState>
// build(): starts the schedule load. selectCategory(c): loads on first use.
// selectWeekday(d): state only. refresh(): reloads the current category.
```

Stale answers are dropped with a counter per category.

### 4. Skeleton

`lib/core/widgets/skeleton.dart`: `SkeletonBox` (color pulse between `AppTheme.cardDark` and `0xFF2A2E39`, 1000 ms, own controller), `SkeletonPosterGrid` (two columns, not scrollable), `SliverSkeletonEpisodes({required bool grid})`.

| Call site (before the task) | Becomes |
| --- | --- |
| `explore_screen.dart:94` spinner | `SkeletonPosterGrid` |
| `explore_screen.dart:165` image placeholder | `SkeletonBox` |
| `search_screen.dart:81` spinner | `SkeletonPosterGrid` |
| `search_screen.dart:187` spinner in the image placeholder | `SkeletonBox` |
| `detail_screen.dart:296` spinner | `SliverSkeletonEpisodes` |
| `detail_screen.dart:82`, `library_screen.dart:233` no placeholder | `SkeletonBox` |
| `library_screen.dart:441` image placeholder | `SkeletonBox` |

Stays: the player indicators (`player_screen.dart:698` and `:805`, `player_controls.dart:207`) and the `LinearProgressIndicator` progress bars.

### 5. About

New `lib/core/app_info.dart`: `AppInfo.name = 'DHMobile'`, `version = '1.0.3'`, `buildNumber = '4'`, `playerEngine = 'video_player (ExoPlayer)'`.

| Row | Title | Subtitle |
| --- | --- | --- |
| 1 | `AppInfo.name` | `Version 1.0.3 (build 4)` |
| 2 | Player | `AppInfo.playerEngine` |
| 3 | Content source | `AnimeXin (animexin.dev)` |
| 4 | Credits | Unchanged |
| 5 | Privacy | `No ads. No tracking. History and favorites are stored only on this device.` |

"libVLC", "(Release)", and "100% offline" go. `AppInfo.name` is also the `MaterialApp` title and the Search AppBar title. `test/app_info_test.dart` checks that the `version:` line of `pubspec.yaml` equals `'${AppInfo.version}+${AppInfo.buildNumber}'` and that `android:label` equals `AppInfo.name`.

### 6. Display language

- `lib/core/l10n/app_strings.dart`: `enum AppLanguage { en('en', 'EN - English'), km('km', 'KH - ភាសាខ្មែរ') }` with `fromCode` (falls back to `en`), `enum S { ... }` with two `const Map<S, String>`, `class AppStrings` with `call(S key)`, `fmt(S key, Map<String, Object> args)`, and `weekdayShort(int day)`.
- `StorageService`: `keyLanguage = 'display_language'`, `getLanguageCode()` (default `'en'`), `setLanguageCode(String)`.
- `AppSettings.language`, `SettingsNotifier.setLanguage(AppLanguage)`, and `stringsProvider` in `settings_controller.dart`. Widgets read `ref.watch(stringsProvider)`.
- Settings: a new first section "GENERAL" with "Display Language", same radio dialog style as Quality.
- No `locale` or `supportedLocales` on `MaterialApp`: without `flutter_localizations` there are no Material strings for `km`. Built-in Material tooltips stay English.
- The stored values `'Auto'`, `'English'`, `'Indonesian'`, `'None'` are logic keys in `source_selection.dart`. Only the label is translated.
- Stays English: source titles, the scraper's `'Episode N'` fallback title, the `'Server N'` label, the Library date format.

Strings move in: `main_screen.dart`, `explore_screen.dart`, `search_screen.dart`, `detail_screen.dart`, `library_screen.dart` (`historyEpisodeLabel` gets `{String episodeWord = 'Episode'}`), `settings_screen.dart`, `player_screen.dart` (text only), `player_controls.dart` (tooltips, last).

Khmer concerns: the system Khmer font is used (Roboto has no Khmer glyphs), no font asset. `letterSpacing` 0 for section headers in `km`. Check the 40 px day row, nav labels, tabs, and the 4-column episode cells for clipping. Line wrapping of long Khmer strings is not sure, check on the device. Latin digits. The owner should review the wording.

### 7. Risks

- A skeleton never settles: widget tests use `pump(duration)`, not `pumpAndSettle`.
- Widget tests override `streamProvider` with a fake, and fake shows use `poster: ''`.
- Schedule days are the site's UTC days while times show local, so a late item can sit under the "wrong" local day.
- Upcoming titles in New Series open to "No episodes available".
- Favorites and history saved from the old Explore use episode-post URLs as show id. They still open, but do not match the same show found through the new Explore.
- The zoom to scale 8 redraws text every frame. If it janks, cap it near 5.

Existing tests that change: `test/widget_test.dart` (rewrite), `test/stream_provider_test.dart` (the network-based fallback test is replaced by fake-adapter tests), `test/player_controls_test.dart` (wrap in `ProviderScope` if `PlayerControls` becomes a `ConsumerWidget`).

New tests: `animexin_listing_parser_test`, provider tests with a fake `HttpClientAdapter`, `explore_controller_test`, `app_strings_test`, `settings_controller_test`, `app_info_test`, `skeleton_test`, and widget tests for Explore, Detail, Search, and Settings.

### 8. Deferred by the advisor

Pages 2 and later of New Series and Popular, pull-to-refresh, a Khmer date format in Library, Material built-in tooltips in Khmer, removing the search fallback list and `cleanShowTitle`, a gradient shimmer, reduced-motion handling.

## Dev Results

Implemented by the `dev` subagent, steps 1 to 8. No package, `pubspec.yaml`, or `pubspec.lock` change.

Added:

| File | Content |
| --- | --- |
| `lib/core/app_info.dart` | `AppInfo.name`, `version`, `buildNumber`, `playerEngine`, `contentSource` |
| `lib/core/l10n/app_strings.dart` | `AppLanguage`, `enum S` (99 keys), the English and Khmer tables, `AppStrings` (`call`, `fmt`, `weekdayShort`, `tableOf`) |
| `lib/core/widgets/skeleton.dart` | `SkeletonBox`, `SkeletonPosterGrid`, `SliverSkeletonEpisodes` |
| `lib/domain/models/schedule_entry.dart` | `ScheduleEntry` |
| `lib/data/providers/animexin_listing_parser.dart` | `parseSchedule`, `parseSeriesList` |
| `android/app/src/main/res/values-v31/styles.xml`, `drawable/splash_no_icon.xml` | Launch theme for Android 12 and later: black background, transparent icon |
| `test/fixtures/animexin_schedule.html`, `animexin_popular.html`, `animexin_latest.html` | Listing parts of the source pages of 2026-11-10, cut by the main agent |
| `test/support/fake_stream_provider.dart` | Fake provider for the widget and controller tests |
| `test/app_info_test.dart`, `app_strings_test.dart`, `settings_controller_test.dart`, `settings_screen_test.dart`, `animexin_listing_parser_test.dart`, `explore_controller_test.dart`, `explore_screen_test.dart`, `detail_screen_test.dart`, `search_screen_test.dart`, `skeleton_test.dart` | New tests |

Changed:

| File | Change |
| --- | --- |
| `lib/domain/providers/stream_provider.dart` | `weekday` removed, `schedule()`, `newSeries()`, `popular()` added |
| `lib/data/providers/animexin_stream_provider.dart` | The three new methods (no catch, zero items throws `FormatException`), `search('')` returns `popular()`, the homepage shuffle and its cache removed |
| `lib/data/storage/storage_service.dart` | `keyLanguage`, `getLanguageCode()`, `setLanguageCode()` |
| `lib/features/settings/settings_controller.dart` | `AppSettings.language`, `setLanguage`, `stringsProvider` |
| `lib/features/settings/settings_screen.dart` | Section GENERAL with Display Language, five About rows, strings |
| `lib/features/explore/explore_controller.dart`, `explore_screen.dart` | Categories, day row, skeleton grid, error with Retry, schedule caption |
| `lib/features/detail/detail_screen.dart`, `lib/features/search/search_screen.dart`, `lib/features/library/library_screen.dart` | Skeletons and strings. `historyEpisodeLabel` got `episodeWord` |
| `lib/features/home/main_screen.dart` | Navigation labels from the strings |
| `lib/features/splash/splash_screen.dart` | Rewritten: black, red logo, 2000 ms animation, 350 ms fade, Explore warm-up |
| `lib/features/player/player_screen.dart`, `widgets/player_controls.dart` | Text only. `PlayerControls` is a `ConsumerWidget` |
| `lib/main.dart` | `title: AppInfo.name` |
| `android/app/src/main/res/values/styles.xml`, `drawable/launch_background.xml`, `drawable-v21/launch_background.xml` | Black launch window |
| `test/widget_test.dart`, `test/stream_provider_test.dart`, `test/player_controls_test.dart`, `test/history_episode_label_test.dart` | Rewritten or extended for the new behaviour. The network-based test is gone |

Deleted: `android/app/src/main/res/values-night/styles.xml`.

Deviations from the plan, as reported by Dev:

| # | Deviation | Reason |
| --- | --- | --- |
| 1 | `AppInfo.contentSource` added | No literal in Settings |
| 2 | The splash fades through the alpha of the text color, not an `Opacity` widget | Same look, no extra layer during the zoom |
| 3 | `SplashScreen` has `logoKey`, `animationDuration`, `handoverDuration` | For tests |
| 4 | Day row is 44 px high and uses `InkWell` | Room for Khmer glyphs |
| 5 | Search and Detail errors show a fixed text, not the raw error | Same as Explore, a raw error can hold a URL |
| 6 | The Detail episode cell uses `S.episodeShort`. The Explore caption stays `EP n` in both languages | It comes from the stored `Show.episodeCount` |
| 7 | The listing parser reads `data-src` before `src` too | One helper |
| 8 | `fmt` replaces placeholders in one pass | A source title with braces is not expanded again |
| 9 | Not in `S`: the credits body and the `'Donghua'` fallback of a favorite card | Names are not translated |
| 10 | The Detail widget test uses `ProviderScope(retry: (_, _) => null)` | Riverpod 3 retries a `FutureProvider` by itself and would leave a timer |

Behaviour to know:

- `search('')` can now throw. The Search screen shows an error with Retry instead of the built-in list.
- The player's `Error: {error}` still shows the raw error, since the player change is text only.
- Dev ran `dart format lib/domain` once by mistake, which reformatted four unrelated model files, and reverted them by hand. `git diff -- lib/domain/models` is empty (checked by the main agent).

Checks reported by Dev on its final tree: format `Formatted 35 files (0 changed)`, analyze `No issues found!`, test `+153: All tests passed!`, build `√ Built build\app\outputs\flutter-apk\app-debug.apk`.

## QA Results

The first `qa-review` run was stopped before it reported (usage limit). Before the second run the main agent changed three Khmer strings to "Server" and made `exploreEmptyDay` say "the selected day", and exempted `S.playerServerWord` from the Khmer-letter test.

### Round 1 (second run): Accepted

By the `qa-review` subagent, independent, no edits to the repo. Mutation runs in a copy outside the repo.

| ID | Severity | Location | Finding | Decision |
| --- | --- | --- | --- | --- |
| L1 | Low | `android/.kotlin/` | Kotlin build output, untracked, not covered by `android/.gitignore` | Not staged. Ignore rule left for the owner |
| L2 | Low | `player_screen.dart` `_errorMessage = ...(S.playerNoServer)` | The text is stored once, so a language switch while that error shows keeps the old language | Accepted as is: the language is changed in Settings, not in the player |
| L3 | Low | `player_screen.dart` `S.playerError` | Still shows the raw error, the player change was text only | Known, deferred |
| N1 | Note | `player_screen.dart` `player.init` | Logs the full stream URL in debug builds. Older than this task | Not changed |

QA checks: format on the 35 changed or added Dart files `Formatted 35 files (0 changed)`, analyze `No issues found! (ran in 26.3s)`, test `00:58 +153: All tests passed!`. Eleven mutations (stale counter, dispose guard, lazy load, weekday by position, language save, `search('')` fallback, `data:` poster, zero items, UTC, day change request, splash warm-up) were all caught by the tests. Fixture counts confirmed independently. QA did not build and did not use the device.

QA could not verify: anything on the device (light mode, Android 7 to 11, OEM splash overrides, a flash at the handover, playback from Explore, the language after a restart on Hive, Khmer clipping), the APK build, and the Khmer wording.

### Device check so far (main agent, 2026-11-10, debug build of the Dev tree)

| Case | Result |
| --- | --- |
| Cold start, system dark mode | Pass: black, then the red "DHMobile" logo growing, then black, then Explore. No icon splash, no white frame (9 frames captured) |
| Cold start, system light mode | Not tested: it needs a system setting change on the owner's phone |
| Schedule | Log `schedule total=61 days=8,6,11,7,6,14,9`. Tuesday shows the same first titles as the source page, with captions like `EP 392 · 10:35` |
| New Series, Popular | Log `seriesList order=latest count=30` and `order=popular count=30`, the Popular grid shows titles with status |
| Display language | The owner switched to KH on the phone: Settings, the quality dialog, and the navigation labels show Khmer without clipping |
| Not checked yet | Opening a show from Explore and playing it, Detail and Search skeletons, the About rows, language after a restart, Library and Detail in Khmer |

The check stopped when the owner moved to another app on the phone.

Open before commit:

- Run QA again and fix its findings.
- Khmer wording the main agent wants to change: use "Server" instead of "ម៉ាស៊ីនមេ" (`playerServerWord`, `playerNoServer`, `selectSource`), and make `exploreEmptyDay` say "the selected day", not "today".
- Finish the device check, then Docs, final validation, and the commit.

## Documentation Updates

By the `docs` subagent. `AGENTS.md`: the structure listing names `AppInfo`, `core/l10n/`, `core/widgets/`, `ScheduleEntry`, the listing parser, `test/fixtures/`, and `test/support/`. Two new coding rules: user-visible text goes through `stringsProvider` and an `S` key with English and Khmer, and the `pubspec.yaml` version changes together with `AppInfo` (checked by `test/app_info_test.dart`). `README.md` is still the Flutter template and says nothing about these areas, so it was not changed.

## Final Validation

Run by the main agent on the final tree:

| Check | Result |
| --- | --- |
| `dart format` on the 35 changed or added Dart files | `Formatted 35 files (0 changed)` |
| `flutter analyze --no-pub` | `No issues found! (ran in 18.7s)` |
| `flutter test --no-pub` | `00:23 +153: All tests passed!` |
| `flutter build apk --debug --no-pub` | `√ Built build\app\outputs\flutter-apk\app-debug.apk` |
| `git status` | Not staged: `android/.kotlin/` (build output) and `team/Tasks/TASK-016-apk-organization-by-abi.md` (another session) |

## Git Commit

- Commit Message: feat(app): add Netflix-style splash, source schedule, skeletons and Khmer language [TASK-015]
- Commit Hash:

## Final Report

Committed on the owner's instruction ("Commit ឥឡូវ") with the device check not finished.

- Implemented: one black splash with the red logo animation, Explore with Schedule (every show of each day from the source), New Series, and Popular, skeleton loading in Explore, Detail, and Search, a corrected About section, and Display Language with "EN - English" and "KH - ភាសាខ្មែរ".
- QA: Accepted, Lows only.
- Checks: format clean, analyze clean, 153 tests pass, debug APK builds.
- TASK-014 retest: L1 and L2 passed on the device, L4 partly covered.

## Notes and Limitations

Not verified on the device (the phone was disconnected):

- Cold start in light mode, on Android 7 to 11, and a flash at the handover.
- Opening a show from Explore and playing it, the Detail and Search skeletons, the About rows.
- The language after a restart on Hive, Khmer clipping in Library and Detail.

Known limits:

- Schedule days are the site's UTC days while times show local, so a late item can sit under the neighbouring local day.
- "New Series" includes "Upcoming" titles, which open with no episodes.
- Only the first page (30) of New Series and Popular is loaded.
- Favorites and history saved from the old Explore keep episode-post URLs as show id.
- The splash no longer shows the credit lines. They stay in Settings, About.
- QA L2 (player error text keeps the old language) and L3 (raw player error) are not changed.
- The Khmer wording needs the owner's review, for example "ព្រហ" for Thursday and "{count} ភាគ" for history items.

- Paused by the owner on 2026-11-10, before QA, Docs, final validation, and the commit. The uncommitted work stays in the working tree. Status set to `Blocked` because no status is named "Paused". TASK-016 (`apk/` organization) runs first.
