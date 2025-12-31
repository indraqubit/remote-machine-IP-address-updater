#!/bin/bash

# Auto build script for IPUpdater project
# Builds both Panel and Agent targets
# Usage: ./build.sh [test]

set -e

PROJECT_NAME="IPUpdater"
SCHEME_PANEL="IPUpdaterPanel"
SCHEME_AGENT="IPUpdaterAgent"
DESTINATION="platform=macOS"
RUN_TESTS="${1:-}"
INFO_PLIST="IPUpdaterPanel/Info.plist"

echo "Building IPUpdater project..."
echo ""

# Get current build number and increment
if [ -f "${INFO_PLIST}" ]; then
    CURRENT_BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "${INFO_PLIST}" 2>/dev/null || echo "1")
    NEW_BUILD=$((CURRENT_BUILD + 1))
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${NEW_BUILD}" "${INFO_PLIST}" 2>/dev/null || true
    
    # Get git commit hash (if available)
    GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    
    echo "Build metadata:"
    echo "  Version: $(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${INFO_PLIST}" 2>/dev/null || echo "1.0")"
    echo "  Build: ${NEW_BUILD}"
    echo "  Git commit: ${GIT_COMMIT}"
    echo ""
fi

# Build Panel
echo "Building Panel target..."
xcodebuild \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME_PANEL}" \
    -destination "${DESTINATION}" \
    clean build

echo ""
echo "✓ Panel built successfully"
echo ""

# Build Agent
echo "Building Agent target..."
xcodebuild \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME_AGENT}" \
    -destination "${DESTINATION}" \
    clean build

echo ""
echo "✓ Agent built successfully"
echo ""

# Run tests if requested
if [ "$RUN_TESTS" = "test" ]; then
    echo ""
    echo "Running tests..."
    echo ""
    
    echo "Testing Panel..."
    xcodebuild test \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "${SCHEME_PANEL}" \
        -destination "${DESTINATION}"
    
    echo ""
    echo "✓ Panel tests passed"
    echo ""
    
    echo "Testing Agent..."
    xcodebuild test \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "${SCHEME_AGENT}" \
        -destination "${DESTINATION}"
    
    echo ""
    echo "✓ Agent tests passed"
fi

echo ""
echo "Build complete!"

