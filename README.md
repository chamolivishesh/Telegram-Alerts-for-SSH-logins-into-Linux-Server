# Telegram-Alerts-for-SSH-logins-into-Linux-Server

A lightweight Bash script to automatically set up real-time Telegram notifications whenever someone logs into your Linux server via SSH using PAM (`pam_exec`).

## Features

- **Real-time Alerts**: Sends Telegram messages with username, hostname, login date/time, and remote IP.
- **Session Filtering**: Only triggers when a session opens (`open_session`), avoiding duplicate alerts on logout.
- **Safe Execution**: Uses `session optional` in PAM so SSH access is never blocked if Telegram/network API fails.
- **Idempotent**: Prevents duplicate entries in `/etc/pam.d/sshd` if run multiple times.
- **Placeholder Validation**: Fails fast if default configuration placeholders are left unedited.

## Prerequisites

- Linux server running PAM (Ubuntu/Debian, CentOS/RHEL, etc.)
- `curl` installed (`sudo apt install curl` or `sudo yum install curl`)
- A Telegram Bot Token (created via [@BotFather](https://t.me/BotFather))
- Your Telegram Chat ID (obtainable via [@userinfobot](https://t.me/userinfobot))

## Quick Start

### 1. Download or Create the Setup Script

Save the following script as `setup-ssh-alerts.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# --- CONFIGURATION ---
TOKEN="INPUT_VALUE_HERE:INPUT_VALUE_HERE"
CHAT_ID="INPUT_VALUE_HERE"
SCRIPT_PATH="/usr/local/bin/telegram-ssh-login.sh"
PAM_FILE="/etc/pam.d/sshd"

# Ensure script is run with sudo/root
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run as root (use sudo)." >&2
  exit 1
fi

# Validate configuration values before proceeding
if [[ "$TOKEN" == *"INPUT_VALUE_HERE"* ]] || [[ "$CHAT_ID" == *"INPUT_VALUE_HERE"* ]]; then
  echo "Error: You must set valid TOKEN and CHAT_ID values before running this script." >&2
  exit 1
fi

echo "==> Creating Telegram alert script at $SCRIPT_PATH..."

cat << 'EOF' > "$SCRIPT_PATH"
#!/bin/sh

# Trigger only when an SSH session opens (ignores logout/close events)
if [ "$PAM_TYPE" != "open_session" ]; then
    exit 0
fi

TOKEN="YOUR_TOKEN_HERE"
ID="YOUR_CHAT_ID_HERE"
HOSTNAME=$(hostname -f)
DATE="$(date +"%d.%b.%Y -- %I:%M:%S %p")"
MESSAGE="<b><code>$PAM_USER</code></b> did action: <code>'$PAM_TYPE'</code> at <u>$DATE</u> on $HOSTNAME from IP: <code>$PAM_RHOST</code> !"
URL="[https://api.telegram.org/bot$TOKEN/sendMessage](https://api.telegram.org/bot$TOKEN/sendMessage)"

curl -s -X POST "$URL" -d chat_id="$ID" -d text="$MESSAGE" -d parse_mode='HTML' > /dev/null 2>&1

exit 0
EOF

# Replace placeholders with actual credentials
sed -i "s|YOUR_TOKEN_HERE|$TOKEN|g" "$SCRIPT_PATH"
sed -i "s|YOUR_CHAT_ID_HERE|$CHAT_ID|g" "$SCRIPT_PATH"

# Make script executable
chmod +x "$SCRIPT_PATH"

echo "==> Updating PAM configuration in $PAM_FILE..."

# Check if rule already exists to avoid duplicate entries
if ! grep -qF "$SCRIPT_PATH" "$PAM_FILE"; then
    echo "" >> "$PAM_FILE"
    echo "# Telegram SSH login notification" >> "$PAM_FILE"
    echo "session optional pam_exec.so seteuid $SCRIPT_PATH" >> "$PAM_FILE"
    echo "==> PAM updated successfully."
else
    echo "==> PAM entry already present, skipping line append."
fi

echo "==> Setup complete! Test by opening a new SSH connection."
```

### 2. Configure Credentials

Edit `setup-ssh-alerts.sh` and set your actual values for `TOKEN` and `CHAT_ID`:

```bash
TOKEN="123456789:ABCdefGhIJKlmNoPQRsTUVwxyZ"
CHAT_ID="987654321"
```

### 3. Run the Script

Make the script executable and run it with `sudo`:

```bash
chmod +x setup-ssh-alerts.sh
sudo ./setup-ssh-alerts.sh
```

## Testing

Open a new SSH session to your server in a separate terminal window:

```bash
ssh user@your-server-ip
```

You should instantly receive a Telegram message structured like:

> **`ubuntu`** did action: `'open_session'` at <u>30.Jul.2026 -- 02:45:00 AM</u> on my-server from IP: <code>203.0.113.195</code> !

## Troubleshooting

- **No message received?** Verify your bot token and chat ID using manual `curl`:
  ```bash
  curl -s -X POST "[https://api.telegram.org/bot](https://api.telegram.org/bot)<YOUR_TOKEN>/sendMessage" -d chat_id="<YOUR_CHAT_ID>" -d text="Test"
  ```
- **Execution log issues?** Check system log entries for PAM execution details:
  ```bash
  sudo tail -f /var/log/auth.log
  ```
  *(Or `sudo journalctl -u sshd -f` on systemd units)*

## License

MIT
