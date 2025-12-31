# agents.md — REVISED (v1.1)

## Purpose

Defines **all observable agent behavior**.
Agent is **IP-change driven only**.

---

## Agent Identity (UNCHANGED)

* Headless LaunchAgent
* Event-driven
* Short-lived
* No UI
* Exit after decision

---

## GIVEN / WHEN / THEN — CORE BEHAVIOR (REVISED)

### 1. Disabled Agent

| Given                  | When         | Then             |
| ---------------------- | ------------ | ---------------- |
| config.enabled = false | Agent starts | Exit immediately |

---

### 2. Missing / Invalid Config

| Given           | When         | Then |
| --------------- | ------------ | ---- |
| Config missing  | Agent starts | Exit |
| Config invalid  | Agent starts | Exit |
| Unknown version | Agent starts | Exit |
| Email empty     | Agent starts | Exit |

---

### 3. Network Preconditions (REVISED)

| Given                  | When         | Then |
| ---------------------- | ------------ | ---- |
| Active interface ≠ en0 | Agent starts | Exit |
| IPv4 unavailable       | Agent starts | Exit |
| IPv4 invalid           | Agent starts | Exit |
| IPv4 not RFC1918       | Agent starts | Exit |

---

### 4. First Run

| Given          | When               | Then           |
| -------------- | ------------------ | -------------- |
| No state file  | Valid private IPv4 | Send email     |
| Email succeeds | —                  | Write state    |
| Email fails    | —                  | Exit, no state |

---

### 5. No Change Detected

| Given                 | When       | Then     |
| --------------------- | ---------- | -------- |
| current.ip == last.ip | Agent runs | Exit     |
| State unchanged       | —          | No email |

---

### 6. IP Change Detected

| Given                 | When       | Then                  |
| --------------------- | ---------- | --------------------- |
| current.ip != last.ip | Agent runs | Send email            |
| Email succeeds        | —          | Update state          |
| Email fails           | —          | Exit, state unchanged |

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
  - ip
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

## EXPLICIT NON-BEHAVIORS (UPDATED)

The agent must NEVER:

```
- Resolve SSID
- Depend on SSID
- Compare SSID
- Store SSID
- Guess network type
- Fall back to Ethernet
- Retry
- Poll
```

---

## EXIT RULE (FINAL)

Every test case must end in:

```
exit(0)
```

No resident behavior.

---

**End of agents.md (v1.1)**
