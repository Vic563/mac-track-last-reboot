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

## License

MIT License
