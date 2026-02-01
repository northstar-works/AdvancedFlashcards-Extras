# WebServer → Android Sync Tool

Syncs version metadata from `KenpoFlashcardsWebServer` to the Android app (`KenpoFlashcardsProject-v2`). Handles all the bookkeeping so you can focus on writing Kotlin.

## What It Does

- **Bumps build.gradle** — increments `versionCode` and sets `versionName`
- **Creates/updates version.json** — machine-readable version + WebServer parity tracking
- **Updates CHANGELOG.md** — new entry with TODO-marked WebServer features
- **Updates README.md** — Current Version header + Version History table row
- **Creates Version-AndroidApp-*.txt** — breadcrumb pointing to previous version
- **Creates Fixes *.txt** — build session log with correct header
- **Generates parity report** — markdown comparison of WebServer vs Android features

## What It Does NOT Do

- ❌ Modify .kt source files (you write the Kotlin)
- ❌ Push to GitHub (you review and commit)
- ❌ Modify WebServer files (strictly read-only)
- ❌ Run gradle builds

## Setup

Place the tool files in the `tools` folder alongside your project folders:

```
📁 sidscri-apps (or your projects root)
├── 📁 KenpoFlashcardsWebServer          ← Source (read-only)
├── 📁 KenpoFlashcardsProject-v2         ← Android (updated by tool)
└── 📁 tools
    ├── sync_android.bat                  ← Double-click entry
    ├── sync_webserver_to_android.py      ← Main tool
    ├── README_ANDROID_SYNC_TOOL.md       ← This file
    ├── sync_webserver.bat                ← Existing WS→Packaged tool
    ├── sync_webserver_to_packaged.py     ← Existing WS→Packaged tool
    └── 📁 sync_backups/                  ← Shared backups
```

## Usage

### Just Double-Click (Uses Defaults)

```batch
sync_android.bat
```

### Preview Changes First

```batch
sync_android.bat --dry-run
```

### Specify Upgrade Level

```batch
sync_android.bat --level 2
```

| Level | Type  | Example            |
|-------|-------|--------------------|
| 1     | Patch | v5.6.0 → v5.6.1   |
| 2     | Minor | v5.6.0 → v5.7.0   |
| 3     | Major | v5.6.0 → v6.0.0   |

## Output

### Files Modified

| File | Change |
|------|--------|
| `app/build.gradle` | versionCode +1, versionName bumped |
| `version.json` | Created/updated with parity tracking |
| `CHANGELOG.md` | New entry with TODO-marked features |
| `README.md` | Version header + table row updated |

### Files Created

| File | Content |
|------|---------|
| `Version-AndroidApp-v{X} v{Y}.txt` | Previous version breadcrumb |
| `Fixes v{X} v{Y}.txt` | Build session log with header |
| `tools/parity_report_{date}.md` | Feature comparison report |

### Backups

Before any changes, the tool backs up all files to:

```
tools/sync_backups/android_v{X}_b{Y}_{timestamp}/
```

## Example Session

```
============================================================
  WebServer → Android Sync Tool
  v1.0.0
============================================================

[12:30:15] ℹ️ WebServer: v8.3.0 (build 51)
[12:30:15] ℹ️ Android:   v5.6.0 (build 39)
[12:30:15] ℹ️ Last WS parity: v0.0.0
[12:30:15] ℹ️ Found 8 WebServer version(s) since v0.0.0

  1 = Patch   2 = Minor   3 = Major
  Enter upgrade level (1/2/3): 2

[12:30:18] ℹ️ Upgrade: Minor
[12:30:18] ℹ️ New version: v5.7.0 (build 40)

[12:30:18] ✅ Backup at: tools/sync_backups/android_v5.7.0_b40_...
[12:30:18] ✅ build.gradle → versionCode=40, versionName="5.7.0"
[12:30:18] ✅ version.json updated
[12:30:18] ✅ CHANGELOG.md updated
[12:30:18] ✅ README.md updated
[12:30:18] ✅ Created Version-AndroidApp-v5.7.0 v40.txt
[12:30:18] ✅ Created Fixes v5.7.0 v40.txt
[12:30:18] ✅ Parity report: tools/parity_report_2026-02-01.md

============================================================
  SYNC COMPLETE
============================================================

  ✅ Sync complete!
  📱 New Android version: v5.7.0 (build 40)
  🌐 WebServer parity:    v8.3.0 (build 51)

  Next steps:
    1. Review CHANGELOG.md — fill in actual feature descriptions
    2. Review README.md — update version table row description
    3. Read parity report — decide which WS features to implement
    4. Implement features in Kotlin
    5. Test on device
    6. git add / commit / push
```

## Workflow: Using Both Sync Tools

```
1. Develop features in KenpoFlashcardsWebServer
2. Run sync_webserver.bat        → syncs to Packaged
3. Run sync_android.bat          → bumps Android version + parity report
4. Read parity report            → decide what to implement
5. Write Kotlin in Android Studio
6. Edit CHANGELOG.md             → replace TODOs with actual descriptions
7. Build/test on device
8. git commit + push
```
