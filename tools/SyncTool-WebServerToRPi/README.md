# SyncTool: WebServer → RPi

Push Advanced Flashcards WebServer code and/or data from Windows to a Raspberry Pi.

## First-Time Setup

1. Double-click `SyncTool-WebServerToRPi.bat`
2. Enter your RPi IP address (e.g. `192.168.0.205`)
3. Enter SSH username (e.g. `sidscri`, default is `pi`)
4. Enter SSH password (or press Enter to skip if using SSH keys)
5. Choose `Y` to save settings to `rpi_config.txt`

Settings are saved for future runs — delete `rpi_config.txt` to reset.

## Usage

```batch
SyncTool-WebServerToRPi.bat           (uses saved config)
SyncTool-WebServerToRPi.bat --status  (check RPi service status)
SyncTool-WebServerToRPi.bat --all     (push code + data)
```

## Modes

- `--code` — Push code only (default)
- `--data` — Push data only (with confirmation)
- `--all` — Push code + data (with confirmation)
- `--status` — Show RPi service status
- `--restart` — Restart RPi service
- `--version` — Compare local vs RPi versions

## Config File Format

`rpi_config.txt`:
```
ip=192.168.0.205
user=sidscri
port=22
pass=
```

Leave `pass=` blank if using SSH keys.

## SSH Key Setup (Recommended)

To avoid password prompts:
```bash
ssh-keygen
ssh-copy-id sidscri@192.168.0.205
```

## Troubleshooting

- **Window closes immediately**: Check that you're running from the correct folder
- **Config file not created**: Make sure you answered `Y` when asked to save
- **SSH prompts for password every time**: Either set up SSH keys or enter password when prompted to save it

---

**Tip**: Place this tool at `sidscri-apps\tools\SyncTool-WebServerToRPi\` so it can auto-detect the WebServer location.
