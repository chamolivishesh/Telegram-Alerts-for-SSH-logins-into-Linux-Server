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
URL="https://api.telegram.org/bot$TOKEN/sendMessage"

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
