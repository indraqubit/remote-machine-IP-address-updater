## CURSOR COMPOSER — INITIAL PROMPT (PROJECT BOOTSTRAP)

```
We are building a macOS system consisting of TWO STRICTLY SEPARATED parts:

1) A background AGENT
2) A user-facing CONFIGURATION PANEL

This Composer session is for STRUCTURING the project and tests first.
DO NOT jump to implementation unless explicitly instructed.

GLOBAL CONSTRAINTS:
- Swift 5.9+
- macOS 13+
- No third-party libraries
- No SDKs
- No Node / React / Electron / JUCE / Python
- No polling loops
- No background UI tricks
- Deterministic, event-driven behavior only

ARCHITECTURE (NON-NEGOTIABLE):
- Panel and Agent are separate targets
- Panel NEVER:
  - detects Wi-Fi
  - resolves IP
  - sends email
- Agent NEVER:
  - contains UI
  - depends on panel code
- Communication ONLY via:
  - config file
  - launchctl enable/disable

CONFIG CONTRACT (FROZEN):
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

Config rules:
- JSON file
- Written only by panel
- Read-only for agent
- Missing / invalid → agent exits
- enabled=false → hard exit

STATE (AGENT ONLY, NOT CONFIG):
State
├─ ssid : String
├─ ip   : String
└─ lastChanged : Timestamp

EMAIL BEHAVIOR:
- Triggered ONLY on {SSID + IP} change
- Wi-Fi only
- Private LAN IPv4 only
- One email per change
- Resend REST API via URLSession
- No retries
- Silent failure

DEVELOPMENT MODE:
- Hybrid TDD
- Contract tests first
- Behavior tests second
- Implementation last
- No speculative features
- No refactoring for elegance unless tests demand it

CURRENT TASK:
Start by defining:
- Agent test cases in Given / When / Then table
- Panel test cases in Given / When / Then table

DO NOT write implementation code yet.
DO NOT invent APIs.
If any instruction violates constraints, stop and say:
“Constraint violation — refusing to proceed.”
```

---

## HOW TO USE THIS (IMPORTANT)

* Paste once at project start
* Let Composer respond with **test tables only**
* If it starts coding → stop it immediately
* Say: **“violates initial prompt”**

---

## REALITY CHECK

This prompt forces Cursor to:

* Think before typing
* Respect separation
* Obey TDD
* Stay boring and shippable

Anything else = tool drift.

