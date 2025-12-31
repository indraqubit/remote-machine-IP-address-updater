# IP Updater

A macOS system that **emails the private LAN IPv4 address** of a Mac **when its Wi-Fi network or IP changes**.

Designed for **remote access to headless machines** (e.g. Mac mini over VNC) where Wi-Fi IPs change unpredictably.

---

## What This Is

* A **background LaunchAgent** that reacts to system events
* A **foreground configuration panel**
* Email notifications via **Resend (REST API)**
* Deterministic, short-lived execution

---

## What This Is NOT (IMPORTANT)

```
- Not a daemon
- Not a continuous Wi-Fi monitor
- Not always running
- Not polling
- Not event-stream based
- Not cross-platform
```

If there is no qualifying change → **the agent exits immediately**.

---

## Architecture

This project consists of **two strictly separated components**:

```
[ Panel App ]  →  config.json  →  [ Agent ]
      │
      └→ launchctl enable / disable
```

### Panel

* User-facing macOS app
* Edits configuration only
* Stores API key in Keychain
* Enables / disables the agent

### Agent

* Headless LaunchAgent
* Triggered by:

  * Wi-Fi change
  * System wake
  * Login
* Detects `{SSID + IPv4}` changes
* Sends **one email per change**
* Exits

There is **no runtime coupling** between Panel and Agent.

---

## Platform & Tooling

* macOS 13+
* Swift 5.9+
* Xcode 15+
* Apple frameworks only
* No third-party dependencies
* No SDKs
* No package managers

---

## Build Targets

* `IPUpdaterPanel` — macOS App
* `IPUpdaterAgent` — Command Line Tool (LaunchAgent)

---

## Development (High Level)

1. Open the project in Xcode
2. Build both targets
3. Run tests before implementation changes

Detailed behavior is defined in:

```
ARCHITECTURE.md
CONTRACT.md
agents.md
panel.md
rules.md
```

If code contradicts these documents, **the code is wrong**.

---

## Installation (Development Use)

> This project intentionally avoids installers and auto-magic.

### Agent

* Built as a command-line tool
* Invoked by `launchd`
* Enabled / disabled by the Panel via `launchctl`

### Panel

* Built and run as a standard macOS app
* No background behavior

Exact installation mechanics may change; **behavior contracts will not**.

---

## Configuration

### Config (Panel-owned)

```
~/Library/Application Support/IPUpdater/config.json
```

Contains:

* enabled flag
* email address
* metadata
* Keychain references

### State (Agent-owned)

```
~/Library/Application Support/IPUpdater/state.json
```

Contains:

* last SSID
* last IP
* timestamp

State is **not user-editable**.

---

## Behavior Summary

An email is sent **only if all conditions are met**:

```
- Agent is enabled
- Active interface is Wi-Fi
- IPv4 address is private (RFC1918)
- SSID or IP differs from last known state
```

Otherwise, the agent exits silently.

No retries.
No background loops.
No partial behavior.

---

## Testing

This project follows **Hybrid TDD**:

1. Contracts
2. Given / When / Then tables
3. Tests
4. Implementation

UI gesture automation is intentionally avoided.

---

## Failure Philosophy

* Silent failure is acceptable
* Exit is preferred to recovery
* Deterministic behavior > cleverness

If unsure → **do nothing**.

---

## Status

Architecture and contracts are locked.
Implementation follows tests.

---

## License

Private / internal use.
