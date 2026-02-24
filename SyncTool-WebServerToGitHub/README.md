# SyncTool: WebServer → GitHub

Push KenpoFlashcardsWebServer changes to the GitHub monorepo, so `af-rpi-sync` on the Raspberry Pi can pull the updates.

## Quick Start

Double-click `SyncTool-WebServerToGitHub.bat`:
- Auto-detects WebServer folder (looks for `app.py`)
- Auto-detects monorepo (looks for `sidscri-apps\.git`)
- Syncs files via robocopy (excludes `.venv`, `logs`, `data`)
- Commits: `git commit -m "Update WebServer to vX.Y.Z"`
- Pushes: `git push origin main`

## Command Line Usage

```batch
SyncTool-WebServerToGitHub.bat                (interactive)
SyncTool-WebServerToGitHub.bat --auto         (no prompts)
SyncTool-WebServerToGitHub.bat --dry-run      (preview only)
SyncTool-WebServerToGitHub.bat --no-push      (commit but don't push)
```

## Workflow

1. Make changes to your Windows WebServer
2. Run this tool to sync to GitHub
3. SSH to RPi: `ssh sidscri@192.168.0.205`
4. Pull updates: `af-rpi-sync`

## Options

- `--dry-run` — Preview what would be copied (no changes)
- `--no-commit` — Copy files but don't git commit
- `--no-push` — Commit but don't git push
- `--auto` — Skip all confirmations
- `-h, --help` — Show help

## What Gets Synced

**Included:**
- `*.py` (app.py, helpers, etc.)
- `*.json` (version.json, configs)
- `*.html`, `*.css`, `*.js`
- `requirements.txt`
- `README.md`, `CHANGELOG.md`

**Excluded:**
- `.venv/` (virtual environment)
- `__pycache__/`, `*.pyc`
- `logs/` (runtime logs)
- `data/` (user data, decks, progress)
- `.git/` (git metadata)
- `*.bat` (Windows scripts)

## Prerequisites

- Git installed and configured
- GitHub authentication set up (SSH key or PAT)
- Monorepo cloned to `C:\Users\<username>\Documents\GitHub\sidscri-apps`

## After Syncing

On the Raspberry Pi:
```bash
ssh sidscri@192.168.0.205
af-rpi-sync             # pull from GitHub, restart service
af-rpi-sync --status    # check version and status
```
