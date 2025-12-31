
## Purpose

Defines **all observable behaviors** of the background agent using
**Given / When / Then** tables.

If behavior is not listed here, the agent must **do nothing**.

---

## Agent Identity

* Headless macOS LaunchAgent
* Event-driven execution
* No UI
* No resident loop
* One execution = one decision = exit

---

## Preconditions (Global)

These apply to **all** test cases.

```
- Running on macOS 13+
- Triggered by system event (Wi-Fi change / wake / login)
- Agent invoked once per trigger
```

---

## GIVEN / WHEN / THEN — CORE BEHAVIOR

### 1. Disabled Agent

| Given                  | When              | Then             |
| ---------------------- | ----------------- | ---------------- |
| config.enabled = false | Agent starts      | Exit immediately |
| config.enabled = false | Wi-Fi changes     | Exit immediately |
| config.enabled = false | State file exists | State untouched  |
| config.enabled = false | Any error occurs  | Silent exit      |

---

### 2. Missing / Invalid Config

| Given                  | When         | Then |
| ---------------------- | ------------ | ---- |
| Config file missing    | Agent starts | Exit |
| Config JSON invalid    | Agent starts | Exit |
| Config.version unknown | Agent starts | Exit |
| Email empty            | Agent starts | Exit |
| Keychain ref missing   | Agent starts | Exit |

---

### 3. Network Preconditions

| Given                          | When         | Then |
| ------------------------------ | ------------ | ---- |
| Active interface ≠ Wi-Fi       | Agent starts | Exit |
| Wi-Fi active, SSID unavailable | Agent starts | Exit |
| IPv4 unavailable               | Agent starts | Exit |
| IP = 127.0.0.1                 | Agent starts | Exit |
| IP = 169.254.x.x               | Agent starts | Exit |
| IP not RFC1918                 | Agent starts | Exit |

---

### 4. First Run (No State)

| Given         | When            | Then                   |
| ------------- | --------------- | ---------------------- |
| No state file | Valid SSID + IP | Send email             |
| No state file | Email sent      | Write state            |
| No state file | Email fails     | Exit, no state written |

---

### 5. No Change Detected

| Given             | When          | Then            |
| ----------------- | ------------- | --------------- |
| SSID == last.ssid | IP == last.ip | Exit            |
| State unchanged   | Agent runs    | No email        |
| State unchanged   | Agent runs    | State untouched |

---

### 6. IP Change Only

| Given             | When          | Then                  |
| ----------------- | ------------- | --------------------- |
| SSID == last.ssid | IP != last.ip | Send email            |
| Email succeeds    | —             | Update state          |
| Email fails       | —             | Exit, state unchanged |

---

### 7. SSID Change Only

| Given             | When          | Then                  |
| ----------------- | ------------- | --------------------- |
| SSID != last.ssid | IP == last.ip | Send email            |
| Email succeeds    | —             | Update state          |
| Email fails       | —             | Exit, state unchanged |

---

### 8. SSID + IP Change

| Given             | When          | Then                  |
| ----------------- | ------------- | --------------------- |
| SSID != last.ssid | IP != last.ip | Send email            |
| Email succeeds    | —             | Update state          |
| Email fails       | —             | Exit, state unchanged |

---

## EMAIL SIDE EFFECTS (ASSERTIONS)

When an email is sent:

```
- Exactly ONE HTTP request
- HTTPS only
- URLSession
- Resend REST API
- Includes:
  - email
  - SSID
  - IP
  - metadata.label (if present)
  - metadata.notes (if present)
```

No retries.
No fallback.
No queueing.

---

## STATE PERSISTENCE RULES

```
- Write state atomically
- Only after successful email
- Overwrite previous state
- Corrupt state ignored until next successful send
```

---

## EXIT RULE (FINAL)

Every test case must end in:

```
Process exit
No background activity
No observers left alive
```

If execution does not exit → **bug**.

---

## NON-BEHAVIORS (EXPLICITLY FORBIDDEN)

The agent must NEVER:

```
- Poll
- Retry
- Log verbosely
- Spawn threads unnecessarily
- Cache config
- Modify config
- Notify user locally
```

---

## TDD DIRECTIVE

* Each table row → at least one test
* Tests written BEFORE implementation
* No test → no behavior

---

**End of agents.md**
