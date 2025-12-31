# SSOT Manifest

## Overview

This document catalogs all SSOT declarations and explains where they appear.

## SSOT Documents (Authoritative)

### 1. `agents.md` ⭐
**Authority:** All observable agent behaviors

```markdown
## Purpose

**This document is the SSOT for agent behavior.**

Defines **all observable behaviors** of the background agent using
**Given / When / Then** tables.

If behavior is not listed here, the agent must **do nothing**.

**Never edit this file to match code changes. Edit code to match this file.**
```

**Contains:**
- Agent identity and execution model
- 8 Given/When/Then behavior tables
- Preconditions and exit rules
- Forbidden behaviors
- TDD directive

**Validated by:**
- `IPUpdaterAgentTests/AgentBehaviorTests.swift` (10+ tests)

---

### 2. `contract.md` ⭐
**Authority:** All data structures and ownership

```markdown
## Authority

**This document is the SSOT for data contracts.**

This document defines **immutable contracts** between system components.

If code or tests contradict this document, the code is wrong.

**Never edit this file to match code changes. Edit code to match this file.**
```

**Contains:**
- Config file contract (v1 and v2)
- State file contract
- Change detection rules
- Network validation rules
- Email sending rules
- Ownership summary

**Validated by:**
- `IPUpdaterAgentTests/ConfigContractTests.swift` (10+ tests)
- `IPUpdaterAgentTests/StateContractTests.swift`

---

### 3. `architecture.md` ⭐
**Authority:** System design and separation invariants

```markdown
## Authority

**This document is the SSOT for system architecture.**

This document defines the design invariants and separation constraints.

If code violates these invariants, the code is wrong.

**Never edit this file to match code changes. Edit code to match this file.**
```

**Contains:**
- Component boundaries (Panel vs Agent)
- Communication rules
- Execution model
- Failure philosophy
- Architectural invariants (NEVER VIOLATE)
- Tooling constraints
- Change policy

**Enforced by:**
- Code review (no cross-component imports)
- Architecture tests (implicit)

---

## Explanation & Guidance Documents

### 4. `SSOT.md` 📖
**Purpose:** Full explanation of SSOT philosophy

**Contains:**
- Philosophy of specification-first development
- The three pillars explained in detail
- Authority hierarchy diagram
- Decision rules
- When to modify SSOT
- Scope table for each document
- Examples (adding feature, fixing bug)
- Testing against SSOT
- Compliance checklist

**Audience:** Project leads, reviewers, new team members

---

### 5. `SSOT_QUICK_REFERENCE.md` 📋
**Purpose:** Quick lookup during development

**Contains:**
- Three documents in table format
- Golden rule
- Before you code checklist
- Before you commit checklist
- Three questions to ask
- Common mistakes
- Example: multi-email support

**Audience:** Developers, quick reference

---

## Implementation Documents

### `README.md` 📄
**SSOT Section Added:**
```markdown
## Single Source of Truth (SSOT)

**This project uses specification-first development.**

The **three authoritative documents** are the SSOT:

1. **`agents.md`** — All observable behaviors (Given/When/Then tables)
2. **`contract.md`** — Immutable data contracts & ownership rules
3. **`architecture.md`** — System design & separation invariants

**Authority Hierarchy:**
```
Docs (SSOT)
  ↓
Tests (validate conformance)
  ↓
Code (implements to spec)
```

**Decision Rule:** If code contradicts the docs, **the code is wrong**. Never invert this.

**Full explanation:** See `SSOT.md`
```

---

### `CHANGELOG.md` 📝
**SSOT Enforcement:**
- Documents why contract version was bumped (v1 → v2)
- Explains migration path maintaining backward compatibility
- References that code follows spec, not vice versa

---

## Test Coverage of SSOT

| SSOT Doc | Validated By | Test Count | Status |
|----------|--------------|-----------|--------|
| `agents.md` | AgentBehaviorTests | 10+ | ✅ All scenarios covered |
| `contract.md` | ConfigContractTests | 10+ | ✅ v1 and v2 validated |
| `architecture.md` | (implicit) | Design | ✅ No cross-coupling |

---

## Declaration Matrix

### Where SSOT Is Declared

```
Document            | SSOT Declaration | Authority Section | Scope
--------------------|------------------|-------------------|---------------------------
agents.md           | Line 3-11        | ## Purpose        | All agent behaviors
contract.md         | Line 1-9         | ## Authority      | All data contracts
architecture.md     | Line 3-14        | ## Authority      | All design invariants
README.md           | § Single Source  | ## SSOT            | Project-wide principle
SSOT.md             | Throughout       | Comprehensive      | Philosophy & guidance
SSOT_QUICK_REFERENCE| Throughout       | Table-based        | Quick lookup
```

---

## How to Use These Documents

### 1. **When Starting a Feature**
→ Read `SSOT_QUICK_REFERENCE.md` (5 min)  
→ Find relevant SSOT doc (`agents.md`, `contract.md`, or `architecture.md`)  
→ Check if your feature is already specified  

### 2. **When Writing Code**
→ Check three SSOT docs for constraints  
→ Write tests for the spec (not implementation)  
→ Implement to pass tests  
→ Verify code matches spec  

### 3. **When Reviewing Code**
→ Check if behavior is in `agents.md` ✓  
→ Check if data matches `contract.md` ✓  
→ Check if architecture respects `architecture.md` ✓  
→ Check if tests validate spec ✓  

### 4. **When Updating Spec**
→ Update SSOT document first  
→ Write new tests for spec  
→ Update code to pass new tests  
→ Commit with explanation  
→ Update `CHANGELOG.md`  

---

## Forbidden Practices

❌ Editing SSOT docs to justify code  
❌ Adding features without spec entries  
❌ Changing code to avoid updating spec  
❌ Tests that pass but violate spec  
❌ Undocumented architectural decisions  
❌ Data structures outside contracts  
❌ Behaviors outside Given/When/Then tables  

---

## Compliance Checklist

Before committing:
- [ ] All changes are in `CHANGELOG.md`
- [ ] Relevant SSOT docs updated (if spec changed)
- [ ] Tests validate spec, not implementation
- [ ] Code conforms to all three SSOT docs
- [ ] No spec changed retroactively to match code
- [ ] Architecture invariants respected
- [ ] Data contracts honored

---

## References

**Core SSOT Documents:**
- `agents.md` — Behavior spec
- `contract.md` — Data spec
- `architecture.md` — Design spec

**Guidance Documents:**
- `SSOT.md` — Full philosophy
- `SSOT_QUICK_REFERENCE.md` — Quick lookup
- `SSOT_MANIFEST.md` — This document

**Implementation:**
- `README.md` — Project overview
- `CHANGELOG.md` — Version history
- Source code in `IPUpdaterAgent/` and `IPUpdaterPanel/`
- Tests in `IPUpdaterAgentTests/` and `IPUpdaterPanelTests/`

---

**Principle:** *"The code serves the spec. Never invert this relationship."*

**Status:** ✅ SSOT explicitly documented across all project documents.
