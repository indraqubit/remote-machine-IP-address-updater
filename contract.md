# CONTRACT.md — REVISED (v1.1)

## Authority

Dokumen ini **menggantikan** kontrak sebelumnya terkait network identity.
Jika ada konflik → **dokumen ini menang**.

---

## CONFIG FILE CONTRACT (UNCHANGED)

Tetap sama. **SSID TIDAK ADA DI CONFIG.**

```
Config
├─ version : Int
├─ enabled : Bool
├─ email : String
├─ metadata
│  ├─ label : String
│  └─ notes : String
└─ keychain
   ├─ service : String
   └─ account : String
```

---

## STATE FILE CONTRACT (REVISED)

### Location

```
~/Library/Application Support/IPUpdater/state.json
```

---

### Structure (Authoritative)

```
State
│
├─ ip : String
│
└─ lastChanged : ISO-8601 String
```

### REMOVED ❌

```
ssid
```

### Rules

* State is **agent-owned**
* Written only after **successful email**
* Missing state = first run
* Corrupt state = ignored until next success

---

## NETWORK IDENTITY CONTRACT (AGENT)

### Definition

**Network identity = private IPv4 address only.**

SSID is **explicitly excluded** from agent logic.

---

### Accepted IP

```
- IPv4
- RFC1918 only:
  - 10.0.0.0/8
  - 172.16.0.0/12
  - 192.168.0.0/16
```

### Rejected IP

```
- 127.0.0.1
- 169.254.x.x
- Public IPv4
- IPv6
```

---

## CHANGE DETECTION CONTRACT (REVISED)

### Trigger Condition

```
Change detected if:
  current.ip != last.ip
```

### Non-Triggers

```
- Same IP
- Invalid IP
- Non-Wi-Fi interface
- enabled == false
```

---

## WIFI SCOPE RULE (CLARIFIED)

Agent operates under **Wi-Fi-only intent**, but:

* Agent does **not** resolve SSID
* Agent does **not** depend on SSID
* Agent assumes:

  * `en0` = Wi-Fi
  * Non-`en0` → exit

No fallback. No guessing.

---

## EMAIL CONTRACT (UNCHANGED)

* Sent only on IP change
* One email per execution
* HTTPS only
* Resend REST API
* No retries
* Silent failure

---

## OWNERSHIP SUMMARY (UPDATED)

```
Panel
  └─ config.json
  └─ (optional) SSID display (UI only)

Agent
  └─ state.json (ip only)

Keychain
  └─ API key
```

---

## IMMUTABILITY RULE

Any attempt to:

* Reintroduce SSID into agent
* Use SSID as trigger
* Depend on SystemConfiguration SSID keys

→ **Reject change**

---

**End of CONTRACT.md (v1.1)**
