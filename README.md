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

### 2. Configure Credentials

Edit `setup-ssh-alerts.sh` and set your actual values for `TOKEN` and `CHAT_ID`:

```bash
TOKEN="123456789:ABCdefGhIJKlmNoPQRsTUVwxyZ"
CHAT_ID="987654321"
```

### 3. Run the Script

Make the script executable and run it with `sudo`:

```bash
chmod +x install.sh
sudo ./install.sh
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
