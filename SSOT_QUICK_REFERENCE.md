# SSOT Quick Reference

## Three Documents, One Truth

| Document | Purpose | Authority | Rule |
|----------|---------|-----------|------|
| `agents.md` | Behavior spec (Given/When/Then) | All actions defined here | No behavior outside spec |
| `contract.md` | Data spec (structures, types, ownership) | All data shapes defined here | No data structure outside spec |
| `architecture.md` | Design spec (boundaries, invariants) | All architecture defined here | No violation of invariants |

## Golden Rule

**If code contradicts spec, the code is wrong.**

Never edit spec to match code.

## Before You Code

1. Read the relevant SSOT document(s)
2. Understand the rule or behavior
3. Check if your idea matches the spec
4. If not, update spec first
5. Write tests for the spec
6. Implement

## Before You Commit

- [ ] Code matches spec, not vice versa
- [ ] Tests validate spec, not implementation
- [ ] No spec change without new tests
- [ ] No undocumented behavior
- [ ] No undocumented data structure

## The Three Questions

When you write code, ask:

1. **Is there a spec entry for this?**
   - No → Update spec first
   - Yes → Continue

2. **Do tests validate the spec?**
   - No → Write tests for the spec
   - Yes → Continue

3. **Does code conform to spec?**
   - No → Fix code
   - Yes → Done ✓

## Common Mistakes

❌ "The code works; let's update the spec"  
✓ "Update spec, then update code"

❌ "I'll implement now and spec later"  
✓ "Spec first, then tests, then code"

❌ "This behavior isn't in the spec, but it's useful"  
✓ "Add it to the spec, then implement"

❌ "The test passes, so we're done"  
✓ "The test validates the spec, AND the code passes the test"

## When Specs Change

1. Update SSOT document
2. Update tests to match new spec
3. Update code to match new tests
4. Commit with explanation of why spec changed

## Example: Adding Multi-Email Support

**What we did:**
1. Updated `contract.md` (v1 email → v2 emails array)
2. Updated `agents.md` (added "send to all recipients" behavior)
3. Updated `architecture.md` (no changes, still valid)
4. Wrote new tests validating v2 format
5. Implemented multi-email support
6. All tests passed AND spec satisfied ✓

**What we didn't do:**
- ❌ Add the feature and retroactively document it
- ❌ Change spec to justify existing code
- ❌ Ship without updating all three SSOT docs

## References

- **Full SSOT Explanation:** `SSOT.md`
- **Behavior Reference:** `agents.md`
- **Data Reference:** `contract.md`
- **Architecture Reference:** `architecture.md`
- **Change Log:** `CHANGELOG.md`

---

**Remember:** *"The code serves the spec. Never invert this relationship."*
