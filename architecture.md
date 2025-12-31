# ARCHITECTURE.md

## Authority

**This document is the SSOT for system architecture.**

This document defines the design invariants and separation constraints.

If code violates these invariants, the code is wrong.

**Never edit this file to match code changes. Edit code to match this file.**

---

## System Overview

This project consists of **two strictly separated macOS components**:

```
[ Panel App ]  ──writes──>  [ Config File ]  <──reads──  [ Agent ]
                    │
                    └── controls ──> launchctl
```

There is **no runtime coupling** between Panel and Agent.

---

## Components

### 1. Configuration Panel

**Purpose**

* Human-facing configuration editor

**Characteristics**

* User-launched
* Foreground only
* No background execution
* Exits when window closes

**Responsibilities**

* Render UI
* Enable / disable agent
* Collect email and metadata
* Store API key in Keychain
* Write config file atomically
* Enable / disable LaunchAgent

**Hard Prohibitions**

* No Wi-Fi detection
* No IP resolution
* No network monitoring
* No email sending
* No agent logic
* No state awareness

Panel owns **configuration only**.

---

### 2. Background Agent

**Purpose**

* React to Wi-Fi + IP changes
* Notify user via email

**Characteristics**

* Headless
* Event-driven
* Short-lived execution
* No resident loops

**Responsibilities**

* Detect active Wi-Fi interface
* Resolve private LAN IPv4
* Read config
* Compare with last known state
* Send ONE email on change
* Persist new state
* Exit

**Hard Prohibitions**

* No UI
* No user interaction
* No config mutation
* No polling timers
* No retries
* No long-running loops

Agent owns **runtime state only**.

---

## Communication Rules

### Allowed Channels

* Config file (JSON)
* launchctl enable / disable

### Forbidden Channels

* Direct code calls
* IPC
* Shared memory
* Notifications
* URL schemes
* Environment variables (except secrets)

---

## Execution Model (Agent)

```
Triggered →
  Read config →
    enabled == false ? exit
  Resolve SSID + IP →
    invalid ? exit
  Compare with last state →
    unchanged ? exit
  Send email →
  Persist state →
Exit
```

No other flow is permitted.

---

## Failure Philosophy

* Failure is silent
* Exit is preferred to recovery
* No self-healing
* No retries
* Deterministic behavior only

If assumptions fail → **do nothing**.

---

## Architectural Invariants (NEVER VIOLATE)

* Panel and Agent never import each other
* Panel never performs system observation
* Agent never performs UI work
* Config is immutable at runtime
* State is invisible to user
* Tests define behavior, not comments

---

## Tooling Constraints

* Swift 5.9+
* macOS 13+
* Apple frameworks only
* No third-party dependencies

---

## Change Policy

If a change:

* Breaks separation → reject
* Adds hidden coupling → reject
* Requires more docs → probably wrong

Architecture is **intentionally boring**.

---

**End of document.**

---
