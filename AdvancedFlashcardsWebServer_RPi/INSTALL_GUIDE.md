# 📋 Installation Guide — Advanced Flashcards WebServer on Raspberry Pi 5

Step-by-step guide to deploy the server from your local `sidscri-apps` repo to a Raspberry Pi 5.

---

## Prerequisites

### On Your Raspberry Pi
- Raspberry Pi 5 (RPi 4 also works) with Raspberry Pi OS Bookworm 64-bit
- Connected to your LAN (Ethernet or Wi-Fi)
- SSH enabled: `sudo raspi-config` → Interface Options → SSH → Enable
- Know your Pi's IP: run `hostname -I` on the Pi

### On Your Windows PC
- Git repo at: `C:\Users\Sidscri\Documents\GitHub\sidscri-apps\`
- Project folder: `sidscri-apps\AdvancedFlashcardsWebServer_RPi\`
- SSH client (included with Windows 10+)

---

## Method 1: Install from GitHub (Recommended)

### Step 1 — Push to GitHub first

Make sure the `AdvancedFlashcardsWebServer_RPi` folder is committed and pushed:

```powershell
cd C:\Users\Sidscri\Documents\GitHub\sidscri-apps
git add AdvancedFlashcardsWebServer_RPi/
git commit -m "Add AdvancedFlashcardsWebServer_RPi v1.0.0"
git push
```

### Step 2 — SSH into your Pi

```powershell
ssh pi@<your-pi-ip>
```

### Step 3 — Download and run the installer

```bash
# Clone the repo (or just download the RPi folder)
git clone --depth 1 https://github.com/sidscri/sidscri-apps.git /tmp/sidscri-apps

# Navigate to the RPi project
cd /tmp/sidscri-apps/AdvancedFlashcardsWebServer_RPi

# Make scripts executable
chmod +x *.sh

# Run the installer
sudo ./setup_rpi.sh
```

### Step 4 — Verify

```bash
# Check service status
sudo systemctl status advanced-flashcards

# Check version
af-rpi-sync --status
```

Open a browser on any device on your network:
```
http://<pi-ip>:8009
```

---

## Method 2: Install from Local Repo (via SCP)

If you want to deploy directly from your Windows PC without pushing to GitHub first.

### Step 1 — Copy the RPi project to your Pi

```powershell
# From your Windows PC:
scp -r "C:\Users\Sidscri\Documents\GitHub\sidscri-apps\AdvancedFlashcardsWebServer_RPi" pi@<pi-ip>:/tmp/
```

### Step 2 — SSH into your Pi and run setup

```bash
ssh pi@<your-pi-ip>

cd /tmp/AdvancedFlashcardsWebServer_RPi
chmod +x *.sh
sudo ./setup_rpi.sh
```

The setup script will clone the full `sidscri-apps` repo from GitHub for the actual webserver code. The RPi project folder only contains deployment/management scripts.

---

## Post-Install: Sync Your Data

Your Windows server has existing user accounts and progress. Push that data to the Pi:

### Option A: From Windows (easiest)

```powershell
cd C:\Users\Sidscri\Documents\GitHub\sidscri-apps\AdvancedFlashcardsWebServer_RPi
af-rpi-datasync-to-rpi.bat <pi-ip>
```

### Option B: From RPi (requires SSH on Windows)

```bash
af-rpi-datasync pull <windows-ip>
```

---

## Post-Install: Point Android App to RPi

1. Open the Android app
2. Go to **Admin Settings** → **Sync Settings**
3. Change the server URL to: `http://<pi-ip>:8009`
4. Test with **Push** and **Pull** buttons

---

## Updating the Server

### Quick code update (from GitHub)
```bash
af-rpi-sync
```

### Full update (code + dependencies)
```bash
sudo af-rpi-update
```

### Preview changes before applying
```bash
af-rpi-sync --dry-run
```

---

## Everyday Commands Reference

| What | Command |
|------|---------|
| Start server | `sudo systemctl start advanced-flashcards` |
| Stop server | `sudo systemctl stop advanced-flashcards` |
| Restart | `sudo systemctl restart advanced-flashcards` |
| Check status | `af-rpi-sync --status` |
| View live logs | `sudo journalctl -u advanced-flashcards -f` |
| Pull from GitHub | `af-rpi-sync` |
| Full update | `sudo af-rpi-update` |
| Backup data | `af-rpi-datasync backup` |
| Check data stats | `af-rpi-datasync status` |
| Push data to Windows | `af-rpi-datasync push <win-ip>` |
| Pull data from Windows | `af-rpi-datasync pull <win-ip>` |

---

## Directory Layout After Install

```
/opt/advanced-flashcards/
├── app.py                     ← WebServer (from KenpoFlashcardsWebServer/)
├── version.json               ← WebServer version
├── requirements.txt
├── .env.rpi                   ← Configuration (edit this)
├── .venv/                     ← Python virtual environment
├── runtime/
├── static/                    ← Web UI
├── data/                      ← User data (preserved on updates)
│   ├── profiles.json
│   ├── breakdowns.json
│   ├── decks.json
│   ├── kenpo_words.json
│   └── users/
├── af-rpi-sync.sh             ← CLI tools (also in /usr/local/bin/)
├── af-rpi-update.sh
├── af-rpi-datasync.sh
├── backups/                   ← Rolling data backups
└── repo/                      ← Git clone of sidscri-apps
    ├── KenpoFlashcardsWebServer/
    ├── AdvancedFlashcardsWebServer_RPi/
    └── KenpoFlashcardsProject-v2/
```

---

## Troubleshooting

### "Permission denied" on setup
```bash
chmod +x *.sh
sudo ./setup_rpi.sh
```

### Service won't start
```bash
sudo journalctl -u advanced-flashcards -n 50 --no-pager
# Or try manually:
cd /opt/advanced-flashcards
sudo -u pi .venv/bin/python app.py
```

### Can't reach server from other devices
- Check Pi firewall: `sudo ufw status`
- Verify port: `sudo ss -tlnp | grep 8009`
- Make sure devices are on the same LAN/subnet

### Git clone fails
- Check internet: `ping github.com`
- Try HTTPS: the setup uses `https://github.com/sidscri/sidscri-apps.git`
