

## Authority

This document defines **immutable contracts** between system components.

If code or tests contradict this document, the code is wrong.

---

## CONFIG FILE CONTRACT

### Location

```
~/Library/Application Support/IPUpdater/config.json
```

---

### Format

* JSON
* UTF-8
* Written atomically
* Full snapshot only

---

### Structure (Authoritative)

```
Config
│
├─ version : Int
│
├─ enabled : Bool
│
├─ emails : [String]  (version 2+)
│ OR
├─ email : String     (version 1, deprecated)
│
├─ metadata
│   ├─ label : String
│   └─ notes : String
│
└─ keychain
    ├─ service : String
    └─ account : String
```

---

### Field Rules

#### `version`

* Mandatory
* Current value: `2`
* Unknown value → agent exits
* Agent does not migrate
* Version history:
  - `1`: Single email address (deprecated)
  - `2`: Multiple email addresses (current)

---

#### `enabled`

* Mandatory
* `false` → agent exits immediately
* No override logic

---

#### `emails` (version 2+)

* Mandatory
* Non-empty array
* At least one email
* Panel validates format
* Agent sends to all recipients

#### `email` (version 1, deprecated)

* Mandatory in v1
* Non-empty string
* Panel validates format
* Agent trusts blindly
* **Not used in v2+** (use `emails` instead)

---

#### `metadata`

* Optional
* Informational only
* Must not affect behavior

---

#### `keychain`

* Mandatory
* Contains **references only**
* No secrets allowed in config

---

### Forbidden in Config

```
❌ SSID
❌ IP address
❌ Timestamps
❌ Runtime state
❌ Retry counters
❌ Debug flags
```

---

## STATE FILE CONTRACT (AGENT ONLY)

### Location

```
~/Library/Application Support/IPUpdater/state.json
```

---

### Structure

```
State
│
├─ ssid : String
│
├─ ip   : String
│
└─ lastChanged : ISO-8601 String
```

---

### Rules

* Written only by agent
* Never read or written by panel
* Missing state = first run
* Corrupt state → overwrite after successful email

---

## CHANGE DETECTION CONTRACT

### Trigger Condition

```
Change detected if:
  ssid != last.ssid
   OR
  ip   != last.ip
```

---

### Non-Triggers

```
- Same SSID + same IP
- Invalid IP
- Non-Wi-Fi interface
- enabled == false
```

---

## NETWORK CONTRACT

* Wi-Fi only
* IPv4 only
* RFC1918 only
* Ignore:

  * 127.0.0.1
  * 169.254.x.x

---

## EMAIL CONTRACT

* Sent only on change
* One email per execution (per recipient)
* Sent to all recipients in `emails` array
* HTTPS only
* Resend REST API
* No retries (all-or-nothing attempt)
* Silent failure (all recipients or none)

---

## OWNERSHIP SUMMARY

```
Panel
  └─ config.json

Agent
  └─ state.json

Keychain
  └─ API key (referenced only)
```

---

## IMMUTABILITY RULE

If a proposed change requires:

* Adding a field → bump version
* Changing meaning → bump version
* Adding behavior → write tests first

No exceptions.

---

**End of contract.**
