# LastReboot

A macOS menu bar app that displays the time since your Mac was last rebooted.

## Features

- **Menu Bar Integration**: Lives in your macOS menu bar next to the system icons
- **Live Timer**: Updates every second to show exact uptime
- **Color-Coded Display**: Visual indicator of system health:
  - **Green**: Recently rebooted (< 1 day)
  - **Blue**: Running smoothly (1-7 days)
  - **Orange**: Consider rebooting (1-4 weeks)
  - **Red**: Reboot recommended (> 1 month)
- **Detailed Breakdown**: Shows months, days, hours, minutes, and seconds
- **Last Reboot Date**: Displays exact date and time of last reboot
- **Launch at Login**: Option to start automatically when you log in

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0+ (for building from source)

## Installation

### Building from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/Vic563/mac-track-last-reboot.git
   cd mac-track-last-reboot
   ```

2. Open the project in Xcode:
   ```bash
   open LastReboot/LastReboot.xcodeproj
   ```

3. Build and run (⌘R)

4. The app will appear in your menu bar

### Installing the App

After building, you can copy `LastReboot.app` from the build products to your `/Applications` folder.

## Usage

1. Look for the clock icon in your menu bar showing the uptime
2. Click the icon to see detailed information:
   - Exact reboot date and time
   - Full uptime breakdown
   - Status recommendation
3. Toggle "Launch at Login" to have the app start automatically

## Project Structure

```
LastReboot/
├── LastReboot.xcodeproj/
└── LastReboot/
    ├── LastRebootApp.swift      # App entry point with MenuBarExtra
    ├── UptimeManager.swift      # System uptime detection logic
    ├── MenuBarView.swift        # UI components
    ├── Assets.xcassets/         # App icons and colors
    └── LastReboot.entitlements  # App permissions
```

## How It Works

The app uses the macOS `sysctl` API to query `kern.boottime`, which returns the exact timestamp when the system was last booted. The uptime is calculated as the difference between the current time and the boot time, updated every second.

## Building for Release

### Prerequisites

1. **Apple Developer Account** with **Developer ID** certificate
2. **Xcode** installed with command line tools

### Getting a Developer ID Certificate

To distribute the app outside the App Store (for direct download), you need a Developer ID certificate:

1. Go to [Apple Developer Certificates](https://developer.apple.com/account/resources/certificates/add)
2. Select **"Developer ID Application"**
3. Follow the prompts to create and download the certificate
4. Double-click the downloaded `.cer` file to install in Keychain

### Building and Notarizing

Use the automated build script to build, sign, notarize, and create a distributable DMG:

```bash
./scripts/build-and-notarize.sh
```

This script will:
- Build a release version of the app
- Sign it with your Developer ID certificate
- Submit it to Apple for notarization
- Staple the notarization ticket
- Create a signed `.dmg` installer

The output will be in `dist/LastReboot-latest.dmg`.

### Manual Build

If you prefer to build manually:

```bash
# Build release
xcodebuild -project LastReboot/LastReboot.xcodeproj -scheme LastReboot -configuration Release build

# Find the built app
find ~/Library/Developer/Xcode/DerivedData -name "LastReboot.app" -type d

# Sign (requires Developer ID)
codesign --deep --force --sign "Developer ID Application: Your Name (TEAMID)" \
    --entitlements LastReboot/LastReboot/LastReboot.entitlements \
    --timestamp \
    /path/to/LastReboot.app

# Notarize
xcrun notarytool submit /path/to/LastReboot.app --team-id TEAMID --wait

# Staple
xcrun stapler staple /path/to/LastReboot.app

# Create DMG
hdiutil create -volname LastReboot -srcfolder "/path/to/LastReboot.app" -ov -format UDZO LastReboot.dmg

# Sign DMG
codesign --sign "Developer ID Application: Your Name (TEAMID)" --timestamp LastReboot.dmg
```

### App Icons

The app uses icons defined in `Assets.xcassets/AppIcon.appiconset`. For production:

1. Design a 1024x1024 app icon
2. Export at sizes: 16, 32, 128, 256, 512 (both 1x and 2x for macOS)
3. Use PNG format with transparency
4. Tools: Sketch, Figma, or [icon.kitchen](https://icon.kitchen)

Generate placeholder icons:
```bash
./scripts/generate-icons.sh
```

## License

MIT License
