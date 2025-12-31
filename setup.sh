#!/bin/bash

# Auto setup script for IPUpdater Xcode project
# Automatically generates Xcode project using xcodegen

set -e

PROJECT_NAME="IPUpdater"
PROJECT_FILE="${PROJECT_NAME}.xcodeproj/project.pbxproj"
PROJECT_YML="project.yml"
SCHEME_PANEL="IPUpdaterPanel"
SCHEME_AGENT="IPUpdaterAgent"

echo "=========================================="
echo "IPUpdater Xcode Project Auto Setup"
echo "=========================================="
echo ""

# Check if project already exists
if [ -f "${PROJECT_FILE}" ]; then
    echo "✓ Xcode project found: ${PROJECT_FILE}"
    echo ""
    
    # Check if schemes exist
    if xcodebuild -list -project "${PROJECT_NAME}.xcodeproj" 2>/dev/null | grep -q "${SCHEME_PANEL}"; then
        echo "✓ Panel scheme found"
    else
        echo "✗ Panel scheme not found"
    fi
    
    if xcodebuild -list -project "${PROJECT_NAME}.xcodeproj" 2>/dev/null | grep -q "${SCHEME_AGENT}"; then
        echo "✓ Agent scheme found"
    else
        echo "✗ Agent scheme not found"
    fi
    
    echo ""
    echo "Project appears to be set up. Try running:"
    echo "  ./build.sh test"
    echo ""
    exit 0
fi

# Check if project.yml exists
if [ ! -f "${PROJECT_YML}" ]; then
    echo "✗ Error: ${PROJECT_YML} not found"
    echo "Please ensure project.yml exists in the project root."
    exit 1
fi

echo "Xcode project not found. Attempting auto setup..."
echo ""

# Check for xcodegen
if ! command -v xcodegen &> /dev/null; then
    echo "xcodegen not found. Installing via Homebrew..."
    echo ""
    
    # Check for Homebrew
    if ! command -v brew &> /dev/null; then
        echo "✗ Error: Homebrew not found"
        echo ""
        echo "Please install Homebrew first:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        echo ""
        echo "Or install xcodegen manually:"
        echo "  brew install xcodegen"
        exit 1
    fi
    
    echo "Installing xcodegen..."
    brew install xcodegen
    
    if ! command -v xcodegen &> /dev/null; then
        echo "✗ Error: Failed to install xcodegen"
        exit 1
    fi
    
    echo "✓ xcodegen installed"
    echo ""
fi

# Generate project
echo "Generating Xcode project from ${PROJECT_YML}..."
echo ""

xcodegen generate

if [ ! -f "${PROJECT_FILE}" ]; then
    echo "✗ Error: Failed to generate Xcode project"
    exit 1
fi

echo "✓ Xcode project generated: ${PROJECT_FILE}"
echo ""

# Verify schemes
echo "Verifying project setup..."
echo ""

if xcodebuild -list -project "${PROJECT_NAME}.xcodeproj" 2>/dev/null | grep -q "${SCHEME_PANEL}"; then
    echo "✓ Panel scheme found"
else
    echo "✗ Panel scheme not found"
fi

if xcodebuild -list -project "${PROJECT_NAME}.xcodeproj" 2>/dev/null | grep -q "${SCHEME_AGENT}"; then
    echo "✓ Agent scheme found"
else
    echo "✗ Agent scheme not found"
fi

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Open IPUpdater.xcodeproj in Xcode to verify"
echo "  2. Run: ./build.sh test"
echo ""

