Author: AI Agent
Date: 2026-11-10
Task: TASK-016

# APK archive

Release APK builds of DHMobile (DonghuaPlayer), grouped by chip architecture.
The APKs are not tracked by Git (`*.apk` in `.gitignore`); this file is.

This task renamed the files only. The v1.0.0 and v1.0.1 APKs still show the
launcher name `DonghuaPlayer`; the new file name does not rename the app.

## Folder layout

| Folder | Content |
| --- | --- |
| `apk/universal/` | One APK for every ABI. Installs on any device, largest file. |
| `apk/arm64-v8a/` | 64-bit ARM. Most phones from 2016 on. |
| `apk/armeabi-v7a/` | 32-bit ARM. Older and low-end devices. |
| `apk/x86_64/` | 64-bit x86. Emulators and x86 tablets. |

## Naming rule

```text
DHMobile-<version>[-<variant>]-<abi>.apk
```

- `<version>` is the `version` value of `pubspec.yaml` without the build number.
- `<variant>` is only present for a named build (`auditfix`, `icon-streams`).
- `<abi>` is always the last token, and it matches the folder.

## Old to new names

This task only renamed and moved the old files. It did not rebuild them.

| Old (repo root) | New path |
| --- | --- |
| `DonghuaPlayer-v1.0.0.apk` | `apk/universal/DHMobile-v1.0.0-universal.apk` |
| `DonghuaPlayer-v1.0.1.apk` | `apk/universal/DHMobile-v1.0.1-universal.apk` |
| `DonghuaPlayer-v1.0.1-auditfix.apk` | `apk/universal/DHMobile-v1.0.1-auditfix-universal.apk` |
| `DonghuaPlayer-v1.0.1-icon-streams.apk` | `apk/universal/DHMobile-v1.0.1-icon-streams-universal.apk` |
| `DonghuaPlayer-v1.0.1-arm64.apk` | `apk/arm64-v8a/DHMobile-v1.0.1-arm64-v8a.apk` |
| `DonghuaPlayer-v1.0.1-armv7.apk` | `apk/armeabi-v7a/DHMobile-v1.0.1-armeabi-v7a.apk` |
| `DonghuaPlayer-v1.0.1-x86_64.apk` | `apk/x86_64/DHMobile-v1.0.1-x86_64.apk` |

The SHA256 of each file was unchanged by the move.

## Files

| File | Version | Variant | ABI | Size | Built | SHA256 |
| --- | --- | --- | --- | --- | --- | --- |
| `DHMobile-v1.0.0-universal.apk` | 1.0.0 | - | arm64-v8a, armeabi-v7a, x86_64 | 184.42 MB | 2026-11-03 | `15CF84843528628037AC8907B3CDE482B1B1D4AADDC5BCC9392E35A76DD515B0` |
| `DHMobile-v1.0.1-universal.apk` | 1.0.1 | - | arm64-v8a, armeabi-v7a, x86_64 | 184.42 MB | 2026-11-04 | `AA0CDF31ADE2DF715A5003F8BF882846BD4B5EF6A3AED596AB664E7D67BC355F` |
| `DHMobile-v1.0.1-auditfix-universal.apk` | 1.0.1 | auditfix | arm64-v8a, armeabi-v7a, x86_64 | 184.42 MB | 2026-11-04 | `EBA72B00DFA2756C663ED78C625F32ACE69EEFB45E522E9BD3F55D261F15EAD8` |
| `DHMobile-v1.0.1-icon-streams-universal.apk` | 1.0.1 | icon-streams | arm64-v8a, armeabi-v7a, x86_64 | 184.44 MB | 2026-11-04 | `56000C9E0C5A782D88700F70D6C0DF7369F56E86E86B7C36CC9D4A64AA6A00F7` |
| `DHMobile-v1.0.1-arm64-v8a.apk` | 1.0.1 | - | arm64-v8a | 65.07 MB | 2026-11-04 | `029F17261220982D7D1B1F66FF98D9634BFED6FEF74CB03A0887B6A0A81EE085` |
| `DHMobile-v1.0.1-armeabi-v7a.apk` | 1.0.1 | - | armeabi-v7a | 58.30 MB | 2026-11-04 | `A29ADDFCCB341D937F914EC5FCFAB560E4B7BC898F53AAF2546C00C73830E59F` |
| `DHMobile-v1.0.1-x86_64.apk` | 1.0.1 | - | x86_64 | 72.25 MB | 2026-11-04 | `396A2128A1DE2F3293672F287B056570C6E66A91E6B1CC7A1EE13A7294060BF1` |
| `DHMobile-v1.0.3-arm64-v8a.apk` | 1.0.3 | - | arm64-v8a | 60.74 MB | 2026-11-10 | `FB5F117B5FC6AC91699DE39AAF8E238DFA66FD0581FC518D7C520795A03BD66C` |
| `DHMobile-v1.0.3-armeabi-v7a.apk` | 1.0.3 | - | armeabi-v7a | 53.94 MB | 2026-11-10 | `45ED4E58284D209DAF8D43027F27DD06E22683B4D93A79B6486A4415783464E8` |
| `DHMobile-v1.0.3-x86_64.apk` | 1.0.3 | - | x86_64 | 67.91 MB | 2026-11-10 | `B904FCFE3CC1F43934661368903A9CA280AAC16F92621ACB3FD6E123F6DB661F` |
| `DHMobile-v1.0.4-arm64-v8a.apk` | 1.0.4 | - | arm64-v8a | 60.67 MB | 2026-11-10 | `BC1BF1ED34D247254D5136AAF5C96D06722F7552CB6CB30078F8C8002AD77D22` |
| `DHMobile-v1.0.4-armeabi-v7a.apk` | 1.0.4 | - | armeabi-v7a | 53.90 MB | 2026-11-10 | `D67DACB7A75D9684F8E8AE31D3EAE5D81E5335651D53CB65AB6B9FCA3013F0CD` |
| `DHMobile-v1.0.4-x86_64.apk` | 1.0.4 | - | x86_64 | 67.84 MB | 2026-11-10 | `636B8D1D1742075BBDF540B838AB7932DF6D7A9B813137F83273F9D32EF69D4C` |
| `DHMobile-v1.0.5-arm64-v8a.apk` | 1.0.5 | - | arm64-v8a | 60.74 MB | 2026-11-10 | `44E570AD6ED8C859382F3ADC469C58EAE9D156AEA78FB28AF5209FDD05E31087` |
| `DHMobile-v1.0.5-armeabi-v7a.apk` | 1.0.5 | - | armeabi-v7a | 53.96 MB | 2026-11-10 | `F1FC6F38E5D430FD618F05317960E0313BF719AC0C2CEDD76D68AB26CA373932` |
| `DHMobile-v1.0.5-x86_64.apk` | 1.0.5 | - | x86_64 | 67.91 MB | 2026-11-10 | `6D3DA010E33FB090A76A3517708D578F1BDDA2CF0B549ABCE608C59107F4B8D6` |

Sizes are bytes divided by 1 MiB, rounded to 2 decimals. "Built" is the file
timestamp of the copied build output.

## v1.0.3 provenance

The three v1.0.3 files were built on 2026-11-10 (version `1.0.3+4`) from the
TASK-015 source tree, which was committed as `9151a10` a few minutes after the
build. Their source timestamps all predate the build, and no tracked source file
changed after that commit, so these files are the build of `9151a10`. Rebuild
that commit to reproduce them.

Build command used:

```bash
flutter build apk --release --no-pub --split-per-abi
```

## v1.0.4 provenance

The three v1.0.4 files were built on 2026-11-10 (version `1.0.4+5`) in
TASK-019, from commit `4f1e8ee` (TASK-018) plus the version change of TASK-019.
They add the YouTube-style underline tabs of TASK-017 and TASK-018 to v1.0.3.
Each copy has the same SHA256 as its build output. `aapt dump badging` reports
application id `dhmobile.amscenter.dev`, label `DHMobile`, version name `1.0.4`,
and one ABI per file.

A split build gives every ABI its own version code: 1005 (armeabi-v7a), 2005
(arm64-v8a), 4005 (x86_64). They all upgrade an installed v1.0.3 of the same
ABI, which have 1004, 2004, and 4004 (checked with `aapt`).

Same build command as v1.0.3.

## v1.0.5 provenance

The three v1.0.5 files were built on 2026-11-10 (version `1.0.5+6`) in
TASK-022, from commit `d068b9d` (TASK-021) plus the version change. They add
VLC as the main player with ExoPlayer as fallback (TASK-020) and search across
five sources (TASK-021). The working tree also had a formatting-only change in
`lib/data/providers/stream_resolver.dart`, which does not change the code.
Each copy has the same SHA256 as its build output. `aapt dump badging` reports
application id `dhmobile.amscenter.dev`, label `DHMobile`, version name
`1.0.5`, version codes 1006 (armeabi-v7a), 2006 (arm64-v8a), 4006 (x86_64),
and one ABI per file. They upgrade an installed v1.0.4 of the same ABI.

Same build command as v1.0.3.

## Compatibility warning

- The v1.0.0 and v1.0.1 APKs use application id `dev.amscenter.donghua_player`.
- The v1.0.3, v1.0.4, and v1.0.5 APKs use application id
  `dhmobile.amscenter.dev` and a debug signing key.

Therefore v1.0.3 to v1.0.5 do not upgrade an installed v1.0.x app: Android
treats them as two different apps. Both can be installed at the same time, side
by side. Removing one does not remove the other or its stored data.

Do not publish these APKs. They are local test builds, and v1.0.3 to v1.0.5
are not signed with a release key.
