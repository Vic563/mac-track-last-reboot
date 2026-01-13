#!/bin/bash

# LastReboot Build, Sign, Notarize, and DMG Script
# Run this script to build, sign, notarize, and create a distributable .dmg

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== LastReboot Build & Notarize Script ===${NC}\n"

# Configuration
APP_NAME="LastReboot"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
DMG_DIR="${PROJECT_DIR}/dist"
APP_PATH="${BUILD_DIR}/Release/${APP_NAME}.app"
DMG_PATH="${DMG_DIR}/${APP_NAME}-latest.dmg"
TEAM_ID=""  # Your Apple Team ID (get from Apple Developer portal)

# Check for required tools
echo -e "${YELLOW}Checking prerequisites...${NC}"
command -v xcodebuild >/dev/null 2>&1 || { echo -e "${RED}xcodebuild not found${NC}"; exit 1; }
command -v security >/dev/null 2>&1 || { echo -e "${RED}security not found${NC}"; exit 1; }

# Check for Developer ID certificate
echo -e "${YELLOW}Checking for Developer ID certificate...${NC}"
DEVELOPER_ID=$(security find-identity -v -p codesigning 2>/dev/null | grep "Developer ID Application" | head -1)

if [ -z "$DEVELOPER_ID" ]; then
    echo -e "${RED}ERROR: No Developer ID certificate found!${NC}"
    echo -e "${YELLOW}To get one:${NC}"
    echo "  1. Go to https://developer.apple.com/account/resources/certificates/add"
    echo "  2. Select 'Developer ID Application'"
    echo "  3. Follow prompts to create and download the certificate"
    echo "  4. Double-click the .cer file to install in Keychain"
    echo ""
    echo "Alternatively, set up automatic signing in Xcode:"
    echo "  1. Open the project in Xcode"
    echo "  2. Select the project in the navigator"
    echo "  3. Select the LastReboot target"
    echo "  4. Go to 'Signing & Capabilities'"
    echo "  5. Check 'Automatically manage signing'"
    echo "  6. Select your Team"
    echo ""
    echo "Will build unsigned app for testing purposes only."
    SIGNING_ENABLED=false
else
    echo -e "${GREEN}Found Developer ID certificate${NC}"
    SIGNING_ENABLED=true
    # Extract the certificate hash
    CERT_HASH=$(echo "$DEVELOPER_ID" | awk '{print $2}')
    echo "Certificate hash: $CERT_HASH"
fi

# Get Team ID if not set and signing is enabled
if [ "$SIGNING_ENABLED" = true ] && [ -z "$TEAM_ID" ]; then
    echo -e "${YELLOW}Enter your Apple Team ID (or press Enter to auto-detect):${NC}"
    read -r TEAM_ID

    if [ -z "$TEAM_ID" ]; then
        # Try to extract from certificate
        TEAM_ID=$(security find-certificate -p -c "Developer ID Application" 2>/dev/null | \
            openssl x509 -noout -subject 2>/dev/null | \
            grep -o 'O = [^,]*' | sed 's/O = //' || echo "")
        if [ -n "$TEAM_ID" ]; then
            echo "Detected Team ID: $TEAM_ID"
        else
            echo -e "${YELLOW}Could not auto-detect Team ID. You may need to set it manually.${NC}"
        fi
    fi
fi

# Clean up old builds
echo -e "\n${YELLOW}Cleaning up old builds...${NC}"
rm -rf "${BUILD_DIR}"
rm -rf "${DMG_DIR}"
mkdir -p "${BUILD_DIR}/Release"
mkdir -p "${DMG_DIR}"

# Build the app
echo -e "\n${YELLOW}Building ${APP_NAME}...${NC}"
cd "${PROJECT_DIR}/LastReboot"

xcodebuild \
    -project LastReboot.xcodeproj \
    -scheme LastReboot \
    -configuration Release \
    -derivedDataPath "${BUILD_DIR}/DerivedData" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    build

APP_PATH=$(find "${BUILD_DIR}/DerivedData" -name "${APP_NAME}.app" -type d | head -1)

if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}ERROR: Build failed - app not found${NC}"
    exit 1
fi

echo -e "${GREEN}Build successful!${NC}"
echo "App location: $APP_PATH"

# Sign the app if Developer ID is available
if [ "$SIGNING_ENABLED" = true ]; then
    echo -e "\n${YELLOW}Signing ${APP_NAME}...${NC}"

    # Sign the app with all nested code
    codesign --deep --force --sign "${CERT_HASH}" \
        --entitlements "${PROJECT_DIR}/LastReboot/LastReboot/LastReboot.entitlements" \
        --timestamp \
        "$APP_PATH"

    # Verify signature
    echo -e "\n${YELLOW}Verifying signature...${NC}"
    codesign --verify --verbose=4 "$APP_PATH" || echo -e "${YELLOW}Warning: Signature verification had issues${NC}"

    # Notarize with Apple
    echo -e "\n${YELLOW}Submitting for notarization...${NC}"

    # Upload to Apple for notarization
    NOTARIZE_RESULT=$(xcrun notarytool submit "$APP_PATH" \
        --team-id "${TEAM_ID}" \
        --wait \
        --output-format json 2>&1)

    echo "$NOTARIZE_RESULT" | tee "${BUILD_DIR}/notarization-result.json"

    # Check if notarization succeeded
    if echo "$NOTARIZE_RESULT" | grep -q '"status": "Accepted"'; then
        echo -e "\n${GREEN}Notarization successful!${NC}"

        # Staple the notarization ticket to the app
        echo -e "\n${YELLOW}Stapling notarization ticket...${NC}"
        xcrun stapler staple "$APP_PATH"
        echo -e "${GREEN}Stapling complete!${NC}"
    else
        echo -e "\n${RED}Notarization failed! Check ${BUILD_DIR}/notarization-result.json for details${NC}"
        echo "Common causes:"
        echo "  - Invalid Team ID"
        echo "  - Expired certificate"
        echo "  - App sandbox issues"
    fi
else
    echo -e "\n${YELLOW}Skipping signing (no Developer ID certificate)${NC}"
    echo -e "${YELLOW}The app will work but will show a Gatekeeper warning when opened.${NC}"
fi

# Copy signed app to expected location
cp -R "$APP_PATH" "${BUILD_DIR}/Release/${APP_NAME}.app"

# Create DMG
echo -e "\n${YELLOW}Creating DMG...${NC}"

# Create a temporary directory for DMG contents
TEMP_DMG_DIR=$(mktemp -d)
cp -R "${BUILD_DIR}/Release/${APP_NAME}.app" "${TEMP_DMG_DIR}/"

# Create the DMG
hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${TEMP_DMG_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}"

# Clean up temp dir
rm -rf "${TEMP_DMG_DIR}"

echo -e "${GREEN}DMG created!${NC}"
echo "DMG location: ${DMG_PATH}"

# Sign the DMG if Developer ID is available
if [ "$SIGNING_ENABLED" = true ]; then
    echo -e "\n${YELLOW}Signing DMG...${NC}"
    codesign --sign "${CERT_HASH}" --timestamp "${DMG_PATH}"
    echo -e "${GREEN}DMG signed!${NC}"
fi

# Print summary
echo -e "\n${GREEN}=== Summary ===${NC}"
echo "App:       ${BUILD_DIR}/Release/${APP_NAME}.app"
echo "DMG:       ${DMG_PATH}"

if [ "$SIGNING_ENABLED" = true ]; then
    echo -e "\n${GREEN}App is signed and notarized!${NC}"
    echo "Users can download and run without Gatekeeper warnings."
else
    echo -e "\n${YELLOW}App is NOT signed or notarized.${NC}"
    echo "To fix this:"
    echo "  1. Get a Developer ID certificate from Apple Developer portal"
    echo "  2. Re-run this script"
    echo ""
    echo "For testing, users can right-click the app and select 'Open' to bypass Gatekeeper."
fi

echo -e "\n${GREEN}Done!${NC}"
