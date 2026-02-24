# SyncTool: WebServer → RPi

Push Advanced Flashcards WebServer code and/or data from Windows to a Raspberry Pi.

## Quick Start

Double-click `SyncTool-WebServerToRPi.bat` — it will prompt for:
- **RPi IP address** (e.g. `192.168.0.205`)
- **SSH username** (e.g. `sidscri`)
- **SSH password** (optional — leave blank if using SSH keys)

Settings are saved to `rpi_config.txt` and reused on future runs.

## rpi_config.txt format

```
ip=192.168.0.205
user=sidscri
port=22
pass=              ← blank = SSH prompts each time
```

Delete `rpi_config.txt` to reset all saved settings.

## Command line usage

```batch
SyncTool-WebServerToRPi.bat                    (prompts, then saves)
SyncTool-WebServerToRPi.bat 192.168.0.205
SyncTool-WebServerToRPi.bat 192.168.0.205 --all
SyncTool-WebServerToRPi.bat 192.168.0.205 --data
SyncTool-WebServerToRPi.bat 192.168.0.205 --status
SyncTool-WebServerToRPi.bat 192.168.0.205 --version
SyncTool-WebServerToRPi.bat 192.168.0.205 --code --dry-run
SyncTool-WebServerToRPi.bat --save             (re-prompt and re-save settings)
```

## Modes

| Mode | What It Does |
|------|-------------|
| `--code` | Push WebServer code (default). Excludes data/, logs/, .venv/ |
| `--data` | Push data/ only. Creates RPi backup first. Asks for confirmation |
| `--all` | Push code + data. Creates RPi backup first. Asks for confirmation |
| `--status` | Show RPi service status, version, data size |
| `--restart` | Restart the RPi service |
| `--version` | Compare local vs RPi version |

## About passwords

Native Windows `ssh`/`scp` cannot accept passwords on the command line.

**Options (best to worst):**
1. **SSH key auth** (recommended) — one-time setup, no passwords ever:
   ```
   ssh-keygen
   ssh-copy-id sidscri@192.168.0.205
   ```
2. **sshpass** — if installed, the saved `pass=` is used automatically
3. **Blank `pass=`** — SSH will prompt interactively each time (safe, works always)

## af-rpi-sync (Pi-side alternative)

`af-rpi-sync` runs **on the Pi itself** and pulls from GitHub:
```bash
ssh sidscri@192.168.0.205
af-rpi-sync             # pull from GitHub, rsync to /opt/advanced-flashcards/app/, restart
af-rpi-sync --status    # show version and service state
af-rpi-sync --dry-run   # preview changes
```
Use this when you've pushed code to GitHub and want the Pi to pull it.
Use the SyncTool bat when you want to push directly from Windows without going via GitHub.

## Folder Structure

```
sidscri-apps\
├── tools\
│   └── SyncTool-WebServerToRPi\   ← This tool
│       ├── SyncTool-WebServerToRPi.bat
│       ├── rpi_config.txt          (created after first run)
│       ├── version.json
│       └── README.md
└── KenpoFlashcardsWebServer\       ← Source (auto-detected)
```
