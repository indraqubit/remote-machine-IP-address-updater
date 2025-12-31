# Single Source of Truth (SSOT)

## Philosophy

**This project uses specification-first development.**

Code is derived from specifications, not the other way around. Specifications are immutable until formally revised.

## The Three Pillars of SSOT

### 1. `agents.md` — SSOT for Behavior

**Authority:** All observable agent behaviors must conform to Given/When/Then tables.

**What it defines:**
- When agent runs
- What conditions trigger each behavior
- What the agent must do (and must NOT do)
- Exit conditions

**Example:** If `agents.md` says "agent exits when config is disabled," and code does something else, the code is wrong.

---

### 2. `contract.md` — SSOT for Data

**Authority:** All data structures must conform to contracts.

**What it defines:**
- Config file structure (mandatory fields, types, validation)
- State file structure (ownership, when it's written)
- Data ownership (who reads, who writes, who owns)
- Immutable rules (never violate version semantics)

**Example:** If `contract.md` says "API key must never appear in config.json," and code puts it there, the code is wrong.

---

### 3. `architecture.md` — SSOT for Design

**Authority:** All architectural decisions must conform to invariants.

**What it defines:**
- Component boundaries (Panel vs Agent)
- Communication channels (allowed vs forbidden)
- Execution model (event-driven, no polling)
- Hard prohibitions (what each component MUST NOT do)

**Example:** If `architecture.md` says "Panel never detects network state," and code adds Wi-Fi detection to Panel, the code is wrong.

---

## Authority Hierarchy

```
┌─────────────────────────────────────┐
│  SSOT Documents (immutable)         │
│  • agents.md                        │
│  • contract.md                      │
│  • architecture.md                  │
└─────────────────────────────────────┘
          ↑
          │ Test validates conformance
          │
┌─────────────────────────────────────┐
│  Tests (pass = conforms to spec)    │
│  • AgentBehaviorTests               │
│  • ConfigContractTests              │
│  • PanelBehaviorTests               │
└─────────────────────────────────────┘
          ↑
          │ Code implements to spec
          │
┌─────────────────────────────────────┐
│  Implementation (must conform)       │
│  • Agent.swift                      │
│  • Config.swift                     │
│  • PanelView.swift                  │
└─────────────────────────────────────┘
```

## Decision Rules

### Rule 1: Docs First
**Before writing code or tests:**
1. Read the relevant SSOT document(s)
2. Understand the constraint or behavior
3. Plan your implementation against the spec
4. Write tests that validate the spec
5. Then implement

### Rule 2: Spec is Law
**If there's a conflict:**
- Code vs. Spec → Code is wrong
- Test vs. Spec → Test is wrong
- Comment vs. Spec → Comment is wrong

**Never edit the spec to match code.**

### Rule 3: Test the Spec
**Tests validate that code conforms to spec.**

Not the reverse. A passing test that violates the spec is a **false positive**.

### Rule 4: Break Tests, Not Specs
**If you must change behavior:**
1. Update the SSOT document(s) first
2. Update tests to match new spec
3. Implement new behavior
4. All tests pass AND spec is satisfied

---

## When to Modify SSOT

**SSOT documents are immutable except during formal revisions.**

### Allowed: Clarification
- Adding examples
- Fixing typos
- Restructuring for clarity
- These don't change meaning

### Allowed: New Behaviors
- Add rows to Given/When/Then tables
- Bump contract version if adding fields
- These require new tests

### Forbidden: Retroactive Fixes
- Editing spec to excuse code bugs
- "The code works; let's update the spec"
- Instead: fix the code

### Forbidden: Undocumented Changes
- No feature without a spec entry
- No behavior without tests
- No corner case without documentation

---

## SSOT Documents and Their Scope

| Document | Scope | Authority | Immutability |
|----------|-------|-----------|--------------|
| `agents.md` | Agent behavior (Given/When/Then) | All behaviors must be listed | Immutable (add new, don't change) |
| `contract.md` | Data structures & ownership | All config/state must conform | Immutable (version on change) |
| `architecture.md` | System design & separation | All code must respect boundaries | Immutable (violate = architectural bug) |
| `CHANGELOG.md` | What changed and why | History of versioning decisions | Append-only |

---

## Example: Adding a Feature

**Scenario:** You want to add retry logic to email sending.

**Correct Process:**
1. Check `agents.md` — "No retries" is listed as forbidden
2. **STOP** — This violates the spec
3. If you believe retry is necessary:
   - Update `agents.md` with new Given/When/Then rows
   - Justify the change in the commit message
   - Update tests to validate retry behavior
   - Implement retry
4. If retry is not justified:
   - Don't implement it
   - Code to the spec as written

**Incorrect Process:**
1. Add retry logic to EmailSender
2. Write tests for retry behavior
3. Update `agents.md` to document what you built
4. Commit ✗ WRONG

---

## Example: Fixing a Bug

**Scenario:** Agent doesn't validate Keychain reference, crashes.

**Correct Process:**
1. Check `contract.md` — "Keychain ref missing → agent exits"
2. This is a gap in validation, not a spec violation
3. Update ConfigManager to add validation
4. Write test that validates the check
5. Fix passes ✓ CORRECT

**Incorrect Process:**
1. Agent crashes with nil error
2. Change code to "handle nil gracefully"
3. Call it fixed
4. Don't update tests or spec ✗ WRONG

---

## Testing Against SSOT

### Good Test (validates spec)
```swift
func testAgentExitsWhenKeychainReferenceMissing() {
    // Validates: agents.md → "Keychain ref missing → agent exits"
    let config = validConfig(withKeychainService: "")
    XCTAssertThrowsError(try agent.run())
}
```

### Bad Test (doesn't validate spec)
```swift
func testAgentHandlesNilGracefully() {
    // Doesn't validate any spec entry
    // Tests implementation detail, not behavior
}
```

---

## Compliance Checklist

- [ ] All behaviors in `agents.md` have tests
- [ ] All Given/When/Then rows covered
- [ ] All data in `contract.md` validated
- [ ] All architectural invariants in `architecture.md` respected
- [ ] No code feature without spec entry
- [ ] No behavior without tests
- [ ] No spec change without new tests
- [ ] Code contradicts spec → code fixed, not spec

---

## References

- **Behavior Spec:** `agents.md`
- **Data Spec:** `contract.md`
- **Architecture Spec:** `architecture.md`
- **Change Log:** `CHANGELOG.md`
- **Implementation:** Agent/, Panel/ source files
- **Validation:** *Tests/ directories

---

**End of SSOT document.**

*"The code serves the spec. Never invert this relationship."*
