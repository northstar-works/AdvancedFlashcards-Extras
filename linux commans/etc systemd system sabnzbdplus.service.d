sudo mkdir -p /etc/systemd/system/advanced-flashcards.service.d

sudo tee /etc/systemd/system/advanced-flashcards.service.d/override.conf >/dev/null <<'EOF'
[Service]
User=advanced-flashcards
Group=media
UMask=0002
EOF

sudo systemctl daemon-reload
sudo systemctl restart advanced-flashcards


--------------------------------------------------------------------------


sudo mkdir -p /etc/systemd/system/sabnzbdplus.service.d

sudo tee /etc/systemd/system/sabnzbdplus.service.d/override.conf >/dev/null <<'EOF'
[Service]
User=sabnzbd
Group=media
UMask=0002
EOF

sudo systemctl daemon-reload
sudo systemctl restart sabnzbdplus


---------------------------------------------------------

sudo tee /etc/systemd/system/readarr-audiobooks-b.service >/dev/null <<'EOF'
[Unit]
Description=Readarr Audiobooks (B)
After=network-online.target mnt-lan-media.automount mnt-lan-downloads.automount
Wants=network-online.target

[Service]
User=readarr
Group=media
UMask=0002
Type=simple
ExecStart=__READARR_BIN__ -nobrowser -data=/opt/appdata/readarr-audiobooks-b/config
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF









