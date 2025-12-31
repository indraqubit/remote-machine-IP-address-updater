# IP Updater - Quick Start Guide

## Overview
IP Updater is a macOS agent that monitors Wi-Fi network changes and sends email notifications with your current IP address. Ideal for remote machines or development servers.

**Components:**
- **Agent** (`ipupdater-agent`) — Headless daemon monitoring Wi-Fi/IP changes
- **Panel** (`IPUpdaterPanel.app`) — GUI configuration tool

---

## Installation & Setup

### Quick Steps
1. Build: `bash setup.sh`
2. Open Panel: Open built app from Xcode DerivedData
3. Configure: Enter email, API key
4. **SAVE**: Must click Save to enable agent
5. Done: Agent runs automatically on network changes

### Manual Installation
```bash
# Clone the repository
git clone https://github.com/indraqubit/remote-machine-IP-address-updater.git
cd remote-machine-IP-address-updater

# Build (installs xcodegen, generates project)
bash setup.sh

# Find the Panel app
~/Library/Developer/Xcode/DerivedData/IPUpdater-*/Build/Products/Debug/IPUpdaterPanel.app
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

## How It Works

### The Agent Cycle
1. **Network change detected** — launchctl triggers agent
2. **Config validated** — Reads email config from disk
3. **Network detected** — Gets current private IPv4 address (en0 only)
4. **State compared** — Checks if IP changed since last email
5. **Email sent** (if changed) — Sends to all configured recipients
6. **State saved** — Updates last known IP address
7. **Exit** — Process terminates (no background threads, no polling)

### Important: SAVE = Enable
- **Before SAVE:** Config not loaded, agent not active
- **After SAVE:** Config saved, agent loaded into launchctl
- **Agent runs automatically** on network changes (after SAVE)
- Test Email works anytime but doesn't count as a "state change"

### Edge Cases Explained

**Why didn't I get an email after changing networks?**
- Agent only sends email if **IP address changed** from last saved state
- If you change network and get the same IP, no email sent
- First network change after setup will send email (from "no state" → "first state")
- Agent tracks IP only (SSID is not used for change detection)

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

## Testing & Troubleshooting

### Test Email ≠ Real Email
**Test Email:**
- Shows your actual current IP (and SSID for reference)
- Sends immediately
- Works anytime (doesn't require SAVE)
- For verification only

**Real Email:**
- Sent automatically by agent
- Only when IP address changes
- Requires SAVE to enable agent
- Requires network change to trigger

### Verify Setup Works
1. Open Panel and click **Test Email** → Should arrive in inbox
2. Change Wi-Fi network (or Ethernet connection)
3. Wait 10-30 seconds for agent to trigger
4. Check inbox for email with new IP

### Manual Test
```bash
# Manually run agent to test (shows detected IP/SSID)
~/Library/Developer/Xcode/DerivedData/IPUpdater-*/Build/Products/Debug/ipupdater-agent

# Check if state was saved
cat ~/Library/Application\ Support/IPUpdater/state.json
```

**Note:** Manual run doesn't trigger via launchctl. Real emails happen automatically when network changes after SAVE.

---

## Storage

**Configuration:** `~/Library/Application Support/IPUpdater/config.json`
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

**State File:** `~/Library/Application Support/IPUpdater/state.json`
```json
{
  "ip": "192.168.1.100",
  "lastChanged": "2025-12-31T13:00:00Z"
}
```

**API Key:** Stored securely in macOS Keychain (not in config)

---

## Troubleshooting

### Test Email Fails
- Verify Resend API key is correct and active
- Check email addresses are valid (panel validates RFC 5322 format)
- Ensure internet connection is active
- Check spam folder (Resend may be flagged until domain is verified)
- Check Resend dashboard at [resend.com/emails](https://resend.com/emails) for delivery status

### Agent Not Triggering
- Verify enabled in Panel
- Check `launchctl list | grep ipupdater` shows loaded
- Trigger manually by changing Wi-Fi network
- Verify agent has permissions (may need accessibility approval on first run)

### API Key Not Persisting
- Verify API key was entered in Panel before clicking Save
- Panel stores key in macOS Keychain (not in config file)
- Try removing old key: `security delete-generic-password -s "com.ipupdater.service" -a "resend-api-key"`

### Check Status
```bash
# Is agent loaded?
launchctl list | grep ipupdater

# Check configuration
cat ~/Library/Application\ Support/IPUpdater/config.json

# Check last state
cat ~/Library/Application\ Support/IPUpdater/state.json

# View email history
cat ~/Library/Application\ Support/IPUpdater/history.json

# Verify API key in Keychain
security find-generic-password -s "com.ipupdater.service" -a "resend-api-key" -w
```

### Known Limitations
- **Wi-Fi only on en0:** Currently only detects en0 interface (Ethernet not supported)
- **Single trigger per boot:** Agent runs once per system event; continuous changes may miss intermediate states
- **No email retry:** Failed emails don't retry (by design—prevents spam on network errors)
- **History grows unbounded:** Over months, `history.json` may grow large

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
// Agent only detects IP (SSID removed per contract.md v1.1)
let ip = try detector.detectPrivateIPv4()

// Panel can detect SSID for UI display purposes only
let ssid = try panelDetector.detectWiFiSSID()
```

---

## Safety & Design

### Silent Failure Model
The agent is designed to **never** interrupt system operation:
- No logging (no disk I/O)
- No notifications (no UI popups)
- No retries (fails fast)
- Exits immediately after one decision

If something fails, the agent silently exits. The system remains unaffected.

### Email Security
- API keys stored in **macOS Keychain** (encrypted, per-user)
- Config file is readable (contains no secrets)
- HTTPS only to Resend API
- No local logs of sent emails

### Recent Security Fixes (v2.1+)
- ✅ Email send timeout (10s) — prevents agent hanging
- ✅ RFC 5322 email validation — prevents invalid email formats
- ✅ Improved error messages — better debugging

See `CODE_REVIEW_BLINDSPOTS.md` for full security audit.

---

## Support

- **GitHub Issues:** [Create an issue](https://github.com/indraqubit/remote-machine-IP-address-updater/issues)
- **Security Audit:** See `CODE_REVIEW_BLINDSPOTS.md` for known limitations
- **Documentation:** See `DOCUMENTATION_INDEX.md` for full reference
