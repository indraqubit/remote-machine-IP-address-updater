# Changelog

## v2.0.0 - Multi-Email & Enhanced Observability

### Breaking Changes

- **Config version bumped**: `1` → `2`
  - v1 format (`email: string`) still supported for backward compatibility
  - v2 format (`emails: [string]`) now required for new configs
  - Agent automatically reads both formats; upgrades to v2 on next save

### New Features

#### 1. Multiple Email Recipients
- Config now supports `emails: [string]` array
- Panel UI updated to accept multiple emails (one per line)
- Agent sends notification to all recipients
- All-or-nothing delivery: entire send fails if any recipient fails

#### 2. Debug Logging (Disabled in Release)
- New `Logger.swift` with controlled output
- Logs only in DEBUG builds (disabled in Release)
- Timestamps and file:line references for debugging
- Log levels: debug, info, warn, error
- Output to stderr (non-blocking)

#### 3. Protocol-Based Architecture
- New protocols for dependency injection:
  - `ConfigManaging` (was ConfigManager)
  - `StateManaging` (was StateManager)
  - `NetworkDetecting` (was NetworkDetector)
  - `EmailSending` (was EmailSender)
  - `StateHistoryManaging` (new)
- Concrete implementations conform to protocols
- Test doubles available with `#if DEBUG || TESTING`
- Better testability without touching real resources

#### 4. State History & Backlog
- New `StateHistory.swift` tracks all state changes
- Stored in `history.json` (separate from state.json)
- Entries capped at 100 (to avoid unbounded growth)
- Records:
  - Timestamp
  - SSID and IP
  - Whether email was sent
  - Reason for change (first_run, ssid_change, ip_change, both_change, email_failed)
- Provides observability without parsing logs
- Backward compatible: missing history treated as fresh start

### Updated Files

**Agent:**
- `Logger.swift` (new)
- `NetworkDetectorProtocol.swift` (new)
- `EmailSenderProtocol.swift` (new)
- `ConfigManagerProtocol.swift` (new)
- `StateManagerProtocol.swift` (new)
- `StateHistory.swift` (new)
- `Agent.swift` - updated to use protocols and logging
- `main.swift` - added history manager initialization
- `Config.swift` - added emails array, allEmails helper

**Panel:**
- `PanelView.swift` - changed email input to multi-line TextEditor
- `PanelViewModel.swift` - added email parsing and multi-email validation
- `PanelConfigManager.swift` - supports both v1 and v2

**Tests:**
- `ConfigContractTests.swift` - added v1 and v2 validation tests
- `AgentBehaviorTests.swift` - updated to use v2 config
- `PanelBehaviorTests.swift` - updated for multi-email UI, added v2 tests

**Documentation:**
- `contract.md` - updated for v2 format and multiple emails
- `CHANGELOG.md` (new)

### Migration Path

**For Existing v1 Configs:**
1. Agent continues to read v1 format
2. Panel loads v1 configs
3. When Panel saves, config is upgraded to v2
4. No manual migration needed; transparent on first edit

**For New Installations:**
1. Panel creates v2 config by default
2. Agent validates both v1 and v2

### Testing

**New Tests:**
- v2 config parsing (multiple emails)
- v1 config backward compatibility
- Multi-email validation (both parsing and validation)
- History tracking on success and failure
- Protocol-based mocks

**Test Coverage:**
- Config: v1 and v2 formats
- Agent: all 8 Given/When/Then behaviors with history tracking
- Panel: multi-email input, v1/v2 loading, multi-email save
- Protocols: all four manager protocols with mocks

### Architecture Notes

**Silent Failures Preserved:**
- History recording is optional (`try?`) to avoid hiding real errors
- Email send failure still exits silently
- Config/state errors still exit as before

**Performance:**
- No background work added
- History writing is atomic (single write operation)
- Agent still exits after one execution
- No additional network calls

**Security:**
- API key still in Keychain (not in config)
- Multiple emails don't increase attack surface
- History file contains no secrets

### Upgrade Checklist

- [x] Config contract updated (version 2)
- [x] Agent reads both v1 and v2
- [x] Panel writes v2
- [x] Logging disabled in Release
- [x] Protocol-based architecture
- [x] History tracking
- [x] All tests updated
- [x] Backward compatibility maintained

### Files Changed

```
IPUpdaterAgent/
├── Logger.swift (new)
├── NetworkDetectorProtocol.swift (new)
├── EmailSenderProtocol.swift (new)
├── ConfigManagerProtocol.swift (new)
├── StateManagerProtocol.swift (new)
├── StateHistory.swift (new)
├── Agent.swift (modified)
├── main.swift (modified)
└── Config.swift (modified)

IPUpdaterPanel/
├── PanelView.swift (modified)
├── PanelViewModel.swift (modified)
└── PanelConfigManager.swift (modified)

Tests/
├── ConfigContractTests.swift (modified)
├── AgentBehaviorTests.swift (modified)
└── PanelBehaviorTests.swift (modified)

Documentation/
├── contract.md (modified)
└── CHANGELOG.md (new)
```

### Known Limitations

- Email validation is still basic (contains @ and .)
- No email address deduplication in UI
- History trimming is simple (last 100 entries)
- No migration utility (transparent upgrade only)

### Future Enhancements

- Email template customization
- Retry logic for failed sends (would require version bump)
- Scheduled/batched notifications
- Web dashboard for history viewing
- Multi-recipient analytics
