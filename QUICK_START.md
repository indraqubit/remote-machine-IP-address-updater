# IP Updater - Quick Start Guide

## Overview
IP Updater is a macOS agent that monitors Wi-Fi network changes and sends email notifications with your current IP address. Ideal for remote machines or development servers.

**Components:**
- **Agent** (`ipupdater-agent`) — Headless daemon monitoring Wi-Fi/IP changes
- **Panel** (`IPUpdaterPanel.app`) — GUI configuration tool

---

## Installation & Setup

### 1. Install from Build
```bash
# Clone the repository
git clone https://github.com/indraqubit/remote-machine-IP-address-updater.git
cd remote-machine-IP-address-updater

# Run auto-setup (installs xcodegen, generates Xcode project, builds)
bash setup.sh
```

### 2. Locate Build Artifacts
```bash
~/Library/Developer/Xcode/DerivedData/IPUpdater-fauurzrrismjhcctmehbwlldnzjh/Build/Products/Debug/
```

---

## Configuration (Panel)

### Launch Panel
```bash
open ~/Library/Developer/Xcode/DerivedData/IPUpdater-fauurzrrismjhcctmehbwlldnzjh/Build/Products/Debug/IPUpdaterPanel.app
```

### Configure Settings
1. **Enable Agent** — Toggle to activate monitoring
2. **Email Addresses** — Enter one email per line (recipients for notifications)
3. **Resend API Key** — Get from [resend.com](https://resend.com) (required)
4. **Label** (optional) — Machine name or identifier (e.g., "Remote Server A")
5. **Notes** (optional) — Additional context (e.g., "Production")

### Buttons
- **Test Email** — Send test notification to verify configuration works
- **Save** — Persist configuration and enable agent monitoring
- **Cancel** — Discard changes and exit

---

## Agent Operation

### How It Works
1. **On Wake/Wi-Fi Change** — Agent detects network changes
2. **Reads Config** — Loads email addresses and API key from storage
3. **Detects Network** — Gets current SSID and private IPv4 address
4. **Validates** — Checks RFC1918 (private IP), rejects loopback/link-local
5. **Compares** — If SSID or IP changed since last check:
   - Sends email to all configured recipients
   - Updates state file
6. **Exit** — Process terminates (no polling, no background threads)

### Install as LaunchAgent
Panel automatically manages `launchctl` when you enable/disable the agent.

Manual install:
```bash
# Copy plist to LaunchAgents
cp com.ipupdater.agent.plist ~/Library/LaunchAgents/

# Load/unload manually
launchctl load ~/Library/LaunchAgents/com.ipupdater.agent.plist
launchctl unload ~/Library/LaunchAgents/com.ipupdater.agent.plist
```

---

## Testing

### Test Email
1. Open Panel
2. Fill in email, API key
3. Click **Test Email**
4. Check inbox — should receive test notification

### Manual Agent Run
```bash
~/Library/Developer/Xcode/DerivedData/IPUpdater-fauurzrrismjhcctmehbwlldnzjh/Build/Products/Debug/ipupdater-agent
```

Agent exits immediately after running. No logs by design (silent failure model).

---

## Storage

**Configuration:** `~/.config/ipupdater/config.json`
```json
{
  "version": 2,
  "enabled": true,
  "emails": ["user@example.com"],
  "metadata": {
    "label": "My Machine",
    "notes": "Home Server"
  },
  "keychain": {
    "service": "com.ipupdater.agent",
    "account": "api_key"
  }
}
```

**State File:** `~/.config/ipupdater/state.json`
```json
{
  "ssid": "MyNetwork",
  "ip": "192.168.1.100",
  "timestamp": "2025-12-31T13:00:00Z"
}
```

**API Key:** Stored securely in macOS Keychain (not in config)

---

## Troubleshooting

### Test Email Fails
- Verify Resend API key is correct and active
- Check email addresses are valid
- Ensure internet connection is active

### Agent Not Triggering
- Verify enabled in Panel
- Check `launchctl list | grep ipupdater` shows loaded
- Trigger manually by changing Wi-Fi network

### Check Status
```bash
# Is agent loaded?
launchctl list | grep ipupdater

# Check configuration
cat ~/.config/ipupdater/config.json

# Check last state
cat ~/.config/ipupdater/state.json
```

---

## Architecture

- **Protocol-based design** — All components use protocols for testability
- **No logging** — Silent failure model (agent never logs or notifies UI)
- **No polling** — Event-driven via launchctl triggers
- **Atomic state writes** — Only written after successful email
- **Secure storage** — API key in Keychain, config as JSON

---

## API Reference

### EmailSender
```swift
let sender = EmailSender(apiKey: "re_xxx")
try await sender.sendTestEmail(
    to: "user@example.com",
    ssid: "MyNetwork",
    ip: "192.168.1.100",
    metadata: Config.Metadata(label: "Server", notes: "Test")
)
```

### NetworkDetector
```swift
let detector = NetworkDetector()
let ssid = try detector.detectWiFiSSID()
let ip = try detector.detectPrivateIPv4()
```

---

## Support

- **GitHub Issues:** [Create an issue](https://github.com/indraqubit/remote-machine-IP-address-updater/issues)
- **Documentation:** See `DOCUMENTATION_INDEX.md` for full reference
