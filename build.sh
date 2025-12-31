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

echo "Building IPUpdater project..."
echo ""

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

