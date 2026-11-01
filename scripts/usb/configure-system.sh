#!/bin/bash
set -euo pipefail
useradd -m -s /bin/bash -G systemd-journal owaua
passwd -l root
echo 'owaua ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/owaua-console
chmod 440 /etc/sudoers.d/owaua-console
mkdir -p /opt/models /opt/owaua/data /opt/owaua/scripts /etc/systemd/system/getty@tty1.service.d
cp /tmp/appliance/dashboard.py /opt/owaua/scripts/usb-dashboard.py
cp /tmp/appliance/chat.py /opt/owaua/scripts/usb-chat.py
cat > /opt/owaua/.env <<'EOF'
DISCORD_TOKEN=
BOT_OWNER_IDS=
BOT_MAX_INFLIGHT=1
OWAUA_LOCAL_ONLY=1
OWAUA_LOCAL_BASE_URL=http://127.0.0.1:8080/v1
OWAUA_LOCAL_MODEL=owaua-local
OWAUA_LOCAL_ENABLE_TOOLS=0
OWAUA_LOCAL_TOOLS=0
EOF
chmod 600 /opt/owaua/.env
chown -R owaua:owaua /opt/owaua /opt/models
cat > /etc/systemd/system/owaua-model.service <<'EOF'
[Unit]
Description=Kirmy local Qwen3 4B model (CPU)
After=local-fs.target
[Service]
User=owaua
WorkingDirectory=/opt/llama
Environment=LD_LIBRARY_PATH=/opt/llama
ExecStart=/opt/llama/llama-server -m /opt/models/Qwen3-4B-Q4_K_M.gguf --alias owaua-local --host 127.0.0.1 --port 8080 --ctx-size 8192 --threads 6 --parallel 1 --n-gpu-layers 0 --batch-size 256 --ubatch-size 128 --jinja --chat-template-kwargs '{"enable_thinking":false}'
Restart=on-failure
RestartSec=5
MemoryMax=9G
NoNewPrivileges=true
PrivateTmp=true
[Install]
WantedBy=multi-user.target
EOF
cat > /etc/systemd/system/owaua-bot.service <<'EOF'
[Unit]
Description=Kirmy Discord bot using local AI only
Wants=network-online.target owaua-model.service
After=network-online.target owaua-model.service
[Service]
User=owaua
WorkingDirectory=/opt/owaua
Environment=OWAUA_ENV_FILE=/opt/owaua/.env
Environment=PYTHONPATH=/opt/owaua/src/owaua
Environment=OWAUA_LOCAL_ONLY=1
Environment=OWAUA_LOCAL_ENABLE_TOOLS=0
Environment=OPENAI_API_KEY=
Environment=INCEPTION_API_KEY=
Environment=DEEPSEEK_API_KEY=
Environment=PERPLEXITY_API_KEY=
Environment=GROQ_API_KEY=
Environment=MISTRAL_API_KEY=
ExecStartPre=/usr/bin/rm -f /opt/owaua/data/readiness.json
ExecStart=/opt/owaua/.venv/bin/python /opt/owaua/src/owaua/bot.py
Restart=on-failure
RestartSec=15
MemoryMax=2G
NoNewPrivileges=true
PrivateTmp=true
[Install]
WantedBy=multi-user.target
EOF
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf <<'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin owaua --noclear %I $TERM
EOF
cat > /home/owaua/.bash_profile <<'EOF'
if [ "$(tty)" = /dev/tty1 ]; then
  /opt/owaua/.venv/bin/python /opt/owaua/scripts/usb-dashboard.py
fi
EOF
chown owaua:owaua /home/owaua/.bash_profile
printf 'LABEL=OWAUA_ROOT / ext4 defaults,noatime 0 1\nLABEL=OWAUA_EFI /boot/efi vfat defaults 0 2\n' > /etc/fstab
mkdir -p /boot/efi
systemctl enable NetworkManager owaua-model
systemctl set-default multi-user.target
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
mkdir -p /etc/systemd/journald.conf.d
printf '[Journal]\nSystemMaxUse=128M\nRuntimeMaxUse=64M\n' > /etc/systemd/journald.conf.d/size.conf
echo 'MODULES=most' > /etc/initramfs-tools/conf.d/usb
update-initramfs -u -k all
rm /usr/sbin/policy-rc.d
