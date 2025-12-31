
## Purpose

Defines **all observable behaviors** of the configuration panel using
**Given / When / Then** tables.

If behavior is not listed here, the panel must **not do it**.

---

## Panel Identity

* Foreground macOS app
* User-launched
* Single window
* Exits when closed
* No background execution

---

## Preconditions (Global)

```
- Running on macOS 13+
- User launches panel manually
- No agent code is loaded
```

---

## GIVEN / WHEN / THEN — CORE BEHAVIOR

### 1. Initial Launch

| Given                      | When           | Then                             |
| -------------------------- | -------------- | -------------------------------- |
| No config file exists      | Panel launches | Create in-memory defaults        |
| No config file exists      | Panel shows UI | enabled = false                  |
| Config file exists         | Panel launches | Load config                      |
| Config file corrupt        | Panel launches | Overwrite with disabled defaults |
| Config version unsupported | Panel launches | Overwrite with disabled defaults |

---

### 2. Enable / Disable Toggle

| Given           | When             | Then                    |
| --------------- | ---------------- | ----------------------- |
| enabled = false | User toggles ON  | Update in-memory state  |
| enabled = true  | User toggles OFF | Update in-memory state  |
| Toggle OFF      | User saves       | launchctl disable agent |
| Toggle ON       | User saves       | launchctl enable agent  |
| Toggle OFF      | User cancels     | No change               |

---

### 3. Email Input

| Given                | When             | Then         |
| -------------------- | ---------------- | ------------ |
| Email empty          | User types       | Mark invalid |
| Email invalid format | User types       | Mark invalid |
| Email valid          | User types       | Clear error  |
| Email invalid        | User clicks Save | Block save   |
| Email valid          | User clicks Save | Allow save   |

Panel validates **format only**.

---

### 4. Metadata Fields

| Given          | When       | Then          |
| -------------- | ---------- | ------------- |
| Label empty    | User saves | Save empty    |
| Notes empty    | User saves | Save empty    |
| Label provided | User saves | Persist value |
| Notes provided | User saves | Persist value |

Metadata has **no validation**.

---

### 5. API Key Handling (Keychain)

| Given                | When           | Then                |
| -------------------- | -------------- | ------------------- |
| API key empty        | User saves     | Block save          |
| API key provided     | User saves     | Store in Keychain   |
| API key stored       | Config written | No secret in config |
| Keychain write fails | User saves     | Show inline error   |
| Save fails           | —              | No config written   |

Secrets never touch disk.

---

### 6. Save Semantics

| Given           | When             | Then                    |
| --------------- | ---------------- | ----------------------- |
| Valid inputs    | User clicks Save | Write config atomically |
| Save succeeds   | —                | Close panel             |
| Save fails      | —                | Show inline error       |
| Partial failure | —                | No launchctl change     |

No partial commits.

---

### 7. Cancel Behavior

| Given              | When          | Then              |
| ------------------ | ------------- | ----------------- |
| User edits fields  | Clicks Cancel | Discard changes   |
| User clicks Cancel | —             | No config write   |
| User clicks Cancel | —             | No launchctl call |

Cancel means **nothing happened**.

---

## CONFIG WRITE ASSERTIONS

When config is written:

```
- Full JSON snapshot
- version preserved or set to 1
- enabled matches toggle
- email matches input
- metadata matches inputs
- keychain contains references only
```

---

## LAUNCHCTL ASSERTIONS

```
- Enable → launchctl enable
- Disable → launchctl disable
- No reload
- No immediate execution
```

Panel does **not** run the agent.

---

## ERROR DISPLAY RULES

* Inline only
* No modal alerts
* No auto-fix
* User must act

---

## NON-BEHAVIORS (EXPLICITLY FORBIDDEN)

The panel must NEVER:

```
- Detect Wi-Fi
- Resolve IP
- Send network requests
- Read or write state.json
- Trigger agent execution
- Auto-save
- Run in background
```

---

## TDD DIRECTIVE

* Each table row → at least one test
* Tests written BEFORE implementation
* UI tests validate state, not gestures

---

**End of panel.md**
