# Setup Instructions

## Creating the Xcode Project

This project uses two strictly separated targets (Panel and Agent).

### Option 1: Manual Xcode Project Creation

1. Open Xcode
2. File > New > Project
3. Choose **macOS > App** 
4. Name it `IPUpdaterPanel`
5. Choose SwiftUI for interface
6. Create the project

Then add the Agent target:

1. File > New > Target
2. Choose **macOS > Command Line Tool**
3. Name it `IPUpdaterAgent`
4. Add it to the same project

### Option 2: Using Existing Structure

The source files are already organized in directories:
- `IPUpdaterPanel/` - Panel app source files
- `IPUpdaterAgent/` - Agent source files
- `IPUpdaterPanelTests/` - Panel tests
- `IPUpdaterAgentTests/` - Agent tests

Simply:
1. Create a new Xcode workspace
2. Add existing files from these directories
3. Configure build settings

## Build Settings

### Panel Target
- **Product Name**: IPUpdaterPanel
- **Bundle Identifier**: com.ipupdater.panel
- **Deployment Target**: macOS 13.0
- **Swift Version**: 5.9

### Agent Target
- **Product Name**: ipupdater-agent
- **Deployment Target**: macOS 13.0
- **Swift Version**: 5.9

### Test Targets
- Add `TESTING=1` to Other Swift Flags for test builds
- Link against respective main targets

## Required Capabilities

### Panel
- Keychain Sharing (for API key storage)

### Agent
- Network access (for Wi-Fi detection and email sending)
- Keychain access (for API key retrieval)

## Testing

Make sure test targets have:
- `TESTING=1` defined in build settings
- Access to main target code (set target membership)

Run tests:
```bash
xcodebuild test -scheme IPUpdaterPanel -destination 'platform=macOS'
xcodebuild test -scheme IPUpdaterAgent -destination 'platform=macOS'
```

## Behavior Contracts

All behavior is defined in:
- `architecture.md`
- `contract.md`
- `agents.md`
- `panel.md`

If code contradicts these documents, **the code is wrong**.
