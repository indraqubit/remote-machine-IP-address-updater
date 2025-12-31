# Documentation Index

## 🎯 Start Here

**New to the project?**
1. Read `README.md` (5 min overview)
2. Read `SSOT_QUICK_REFERENCE.md` (5 min philosophy)
3. Pick a task and follow the workflow below

**Reviewing someone's code?**
→ See **Code Review** section below

**Making architectural changes?**
→ See **Architecture Changes** section below

---

## 📚 Documentation Map

### Core SSOT Documents (Authority)

| Document | Purpose | When to Read | Authority |
|----------|---------|-------------|-----------|
| `agents.md` | All agent behaviors (Given/When/Then) | Before implementing agent features | Behavior spec |
| `contract.md` | All data contracts (structures, ownership) | Before touching Config, State | Data spec |
| `architecture.md` | System design (boundaries, invariants) | Before refactoring or adding components | Design spec |

**Golden Rule:** If code contradicts any SSOT doc, **the code is wrong.**

---

### Guidance Documents (Philosophy)

| Document | Purpose | Audience | Read Time |
|----------|---------|----------|-----------|
| `SSOT.md` | Full SSOT philosophy & explanation | Project leads, new team members | 15 min |
| `SSOT_QUICK_REFERENCE.md` | Checklists & quick lookups | All developers | 5 min |
| `SSOT_MANIFEST.md` | Where SSOT is declared | Reviewers, documentation | 10 min |
| `DOCUMENTATION_INDEX.md` | This document | Everyone | 5 min |

---

### Implementation Documents

| Document | Purpose | Status |
|----------|---------|--------|
| `README.md` | Project overview | ✅ Updated with SSOT |
| `SETUP.md` | Build & installation instructions | ✅ Current |
| `CHANGELOG.md` | Version history & changes | ✅ v2.0.0 documented |
| `PROJECT_SUMMARY.md` | Completed components | ✅ Current |

---

### Design Documents

| Document | Purpose |
|----------|---------|
| `panel.md` | Panel-specific design |
| `architecture.md` | System-wide architecture (also SSOT) |

---

## 🔄 Workflows

### Starting a New Feature

```
1. Read SSOT_QUICK_REFERENCE.md (golden rule)
   ↓
2. Check relevant SSOT doc (agents.md / contract.md / architecture.md)
   ↓
3. Is feature already in spec?
   ├─ YES → Continue to step 4
   └─ NO → Update spec first (SSOT.md § "When to Modify SSOT")
   ↓
4. Write tests that validate the spec
   ↓
5. Implement code to pass tests
   ↓
6. Verify code matches spec (all three SSOT docs)
   ↓
7. Update CHANGELOG.md
   ↓
8. Commit
```

### Code Review

```
1. Check if behavior is in agents.md ✓
2. Check if data matches contract.md ✓
3. Check if architecture respects architecture.md ✓
4. Check if tests validate spec ✓
5. If all pass → approve
   If any fail → request changes with reference to SSOT doc
```

### Fixing a Bug

```
1. Identify which SSOT doc applies (agents/contract/architecture)
   ↓
2. Does the bug violate the spec?
   ├─ YES → Update code to match spec
   └─ NO → If spec is incomplete, update spec first
   ↓
3. Write test that validates the spec
   ↓
4. Fix code to pass test
   ↓
5. Update CHANGELOG.md
   ↓
6. Commit with reference to spec
```

### Making Architectural Changes

```
1. Read architecture.md § "Architectural Invariants"
   ↓
2. Does your change violate any invariants?
   ├─ YES → Find alternative design
   └─ NO → Continue to step 3
   ↓
3. If adding new behavior → update architecture.md
   ↓
4. Update agents.md and/or contract.md as needed
   ↓
5. Write comprehensive tests for all changes
   ↓
6. Implement changes
   ↓
7. All tests pass AND all SSOT docs reflect changes → ready
   ↓
8. Update CHANGELOG.md with architectural justification
   ↓
9. Commit
```

---

## 📖 Document Sections Quick Reference

### agents.md Sections
- **Purpose** — SSOT declaration
- **Agent Identity** — What the agent is
- **Preconditions** — Setup assumptions
- **GIVEN/WHEN/THEN** — 8 behavior tables (core spec)
- **Email Side Effects** — Assertions when email is sent
- **State Persistence** — Atomic write rules
- **Exit Rule** — Process termination
- **Non-Behaviors** — Explicitly forbidden
- **TDD Directive** — Testing approach

### contract.md Sections
- **Authority** — SSOT declaration
- **Config File Contract** — Structure, fields, rules
- **State File Contract** — Structure, ownership
- **Change Detection** — What triggers notifications
- **Network Contract** — IPv4 validation rules
- **Email Contract** — Sending rules
- **Ownership Summary** — Who reads/writes what

### architecture.md Sections
- **Authority** — SSOT declaration
- **System Overview** — Component diagram
- **Components** — Panel and Agent definitions
- **Communication** — Allowed/forbidden channels
- **Execution Model** — Agent workflow
- **Failure Philosophy** — Silent exit approach
- **Architectural Invariants** — NEVER VIOLATE
- **Tooling Constraints** — Swift, macOS versions

---

## ✅ Compliance Checklist

**Before every commit:**
- [ ] Behavior is documented in agents.md or it doesn't exist
- [ ] Data conforms to contract.md or it's invalid
- [ ] Code respects architecture.md or it violates design
- [ ] Tests validate the spec, not implementation details
- [ ] CHANGELOG.md updated
- [ ] If spec changed → all tests updated
- [ ] No retroactive edits to SSOT docs to justify code

**Before code review:**
- [ ] All three SSOT docs checked
- [ ] No undocumented features
- [ ] No data outside contracts
- [ ] No architectural violations

---

## 🚀 Quick Commands

**Check what was just implemented:**
```
→ Read CHANGELOG.md for latest version
→ Find the version section
→ Check which SSOT docs were updated
```

**Understand a feature:**
```
→ Check agents.md (Given/When/Then)
→ Check contract.md (if data involved)
→ Check architecture.md (if design involved)
```

**Propose a change:**
```
→ Update relevant SSOT doc(s) first
→ Write tests for new spec
→ Implement to pass tests
→ Verify all SSOT docs satisfied
```

---

## 📞 Questions?

**"How should we handle X?"**
→ Check the three SSOT docs  
→ If not specified, update spec first, then implement  

**"Why does the code do Y?"**
→ Check CHANGELOG.md for version where Y was added  
→ Read the relevant SSOT doc  

**"Can we change Z?"**
→ Check which SSOT doc governs Z  
→ If change violates spec, spec must be updated first  
→ Update spec → update tests → update code → update CHANGELOG  

---

## 📋 File Structure

```
/root
├── README.md                          # Project overview
├── SETUP.md                           # Build instructions
├── SSOT.md                           # SSOT philosophy (full)
├── SSOT_QUICK_REFERENCE.md          # SSOT quick lookup
├── SSOT_MANIFEST.md                 # SSOT declarations
├── DOCUMENTATION_INDEX.md            # This file
├── CHANGELOG.md                      # Version history
├── PROJECT_SUMMARY.md                # Completed work
│
├── agents.md                         # ⭐ SSOT: Behavior
├── contract.md                       # ⭐ SSOT: Data
├── architecture.md                   # ⭐ SSOT: Design
│
├── panel.md                          # Panel design details
├── create_xcode_project.sh          # Setup script
│
├── IPUpdaterAgent/                   # Agent source
│   ├── Agent.swift
│   ├── Config.swift
│   ├── State.swift
│   ├── Logger.swift                 # NEW
│   ├── *Protocol.swift              # NEW (5 files)
│   ├── StateHistory.swift           # NEW
│   ├── *Manager.swift
│   └── main.swift
│
├── IPUpdaterPanel/                   # Panel source
│   ├── PanelApp.swift
│   ├── PanelView.swift
│   ├── PanelViewModel.swift
│   ├── Config.swift
│   └── *Manager.swift
│
├── IPUpdaterAgentTests/              # Agent tests
│   ├── AgentBehaviorTests.swift
│   ├── ConfigContractTests.swift
│   └── StateContractTests.swift
│
└── IPUpdaterPanelTests/              # Panel tests
    └── PanelBehaviorTests.swift
```

---

## 🔑 Key Principles

1. **Specs are immutable** until formally revised
2. **Code serves specs**, not vice versa
3. **Tests validate specs**, not implementation
4. **If code contradicts spec**, the code is wrong
5. **All behaviors must be documented** in SSOT
6. **All changes must have tests** before implementation
7. **All decisions must be justified** in CHANGELOG

---

## 📞 Version History

| Version | Change | Docs Updated |
|---------|--------|--------------|
| 2.0.0 | Multi-email, logging, protocols, history | ✅ All three SSOT docs + CHANGELOG |
| 1.0.0 | Initial release | ✅ All three SSOT docs |

---

**Last Updated:** With v2.0.0 release  
**SSOT Status:** ✅ Explicitly documented across all project docs  
**Compliance:** ✅ All implementation follows spec  

---

*"The code serves the spec. Never invert this relationship."*
