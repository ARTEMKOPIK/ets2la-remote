# ETS2LA Remote

<p align="center">
  <img src="https://raw.githubusercontent.com/ARTEMKOPIK/ets2la-remote/main/assets/unity_build/icon.png" alt="ETS2LA Remote Logo" width="128" height="128">
</p>

<p align="center">
  <strong>Mobile autopilot control for Euro Truck Simulator 2</strong>
</p>

<p align="center">
  <a href="https://github.com/ARTEMKOPIK/ets2la-remote/releases">
    <img src="https://img.shields.io/github/v/release/ARTEMKOPIK/ets2la-remote?include_prereleases&style=flat-square" alt="GitHub release">
  </a>
  <a href="https://github.com/ARTEMKOPIK/ets2la-remote/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/ARTEMKOPIK/ets2la-remote?style=flat-square" alt="License">
  </a>
  <a href="https://github.com/ARTEMKOPIK/ets2la-remote/actions">
    <img src="https://img.shields.io/github/actions/workflow/status/ARTEMKOPIK/ets2la-remote/ci.yml?style=flat-square" alt="Build Status">
  </a>
</p>

---

## Table of Contents

1. [About](#about)
2. [Features](#features)
3. [Screenshots](#screenshots)
4. [Requirements](#requirements)
5. [Installation](#installation)
6. [Architecture](#architecture)
7. [WebSocket Protocol](#websocket-protocol)
8. [Configuration](#configuration)
9. [Localization](#localization)
10. [Contributing](#contributing)
11. [License](#license)
12. [Acknowledgments](#acknowledgments)

---

## About

**ETS2LA Remote** is a Flutter-based Android application that provides mobile control for the [ETS2LA](https://github.com/ETS2LA/Euro-Truck-Simulator-2-Lane-Assist) autopilot system. The app connects to a computer running ETS2LA via WebSocket to display real-time telemetry, control autopilot features, and provide an immersive driver experience.

This app is designed to work alongside the ETS2LA desktop application, enabling you to monitor and control your autonomous trucking operations directly from your Android device.

---

## Features

### Core Functionality

- **Real-time Telemetry Dashboard** — View current speed, cruise control, throttle, brake, and navigation data in real-time
- **Autopilot Control** — Start/stop autopilot, adjust target speed, and monitor autopilot status
- **WebSocket Communication** — Low-latency bidirectional communication with the ETS2LA backend
- **Multi-port Support** — Separate connections for API (REST), Visualization, Navigation, and Pages

### Connection Management

- **LAN Discovery** — Automatic discovery of ETS2LA servers on your local network via mDNS
- **Port Probing** - Smart port scanning to identify available services
- **Connection Profiles** — Save and manage multiple connection profiles with custom names
- **QR Code Sharing** — Export/import connection profiles via QR codes
- **Wake-on-LAN** — Remote wake-up of the host computer using MAC addresses
- **VPN Detection** — Automatic warning when a VPN is active that may interfere with local network discovery
- **Auto-reconnect** — Intelligent reconnection with exponential backoff and jitter

### User Interface

- **Dashboard** — Primary screen showing speed gauge, autopilot status, and key metrics
- **Map View** — Real-time position display on OpenStreetMap
- **Visualization** — Embedded Unity-based 3D visualization of the game world
- **Driver Mode** — Simplified interface optimized for use while driving
- **Customizable Layout** — Rearrange dashboard widgets to suit your preferences

### Accessibility & Customization

- **Theme Customization** — Multiple accent colors and high-contrast mode
- **Reduce Motion** — Simplified animations for accessibility
- **Localization** — Full support for English and Russian languages

### Feedback & Logging

- **Haptic Feedback** — Vibration alerts for autopilot state changes and speed limit warnings
- **Text-to-Speech** — Voice announcements for critical events
- **Trip Logging** — Automatic recording of trip statistics (distance, duration, fuel)
- **Foreground Notification** — Persistent notification showing speed and autopilot status

---

## Screenshots

| Dashboard | Connection | Map View |
|:---:|:---:|:---:|
| ![Dashboard Screenshot Placeholder](#) | ![Connection Screenshot Placeholder](#) | ![Map Screenshot Placeholder](#) |

| Settings | Driver Mode | Visualization |
|:---:|:---:|:---:|
| ![Settings Screenshot Placeholder](#) | ![Driver Mode Screenshot Placeholder](#) | ![Visualization Screenshot Placeholder](#) |

---

## Requirements

### Android Device

- **Android Version**: 8.0 (Oreo) or higher
- **Architecture**: ARM64 (arm64-v8a) recommended
- **Screen Size**: Phone or tablet (responsive layout)

### Computer Running ETS2LA

- **Euro Truck Simulator 2 / American Truck Simulator** with [ETS2LA](https://github.com/ETS2LA/Euro-Truck-Simulator-2-Lane-Assist) running
- **Network**: Same local network as the Android device (or properly configured port forwarding)

### Ports

The app communicates on four ports (default values):

| Service | Default Port | Protocol |
|---------|--------------|----------|
| API (REST) | 37520 | HTTP |
| Visualization | 37522 | WebSocket |
| Navigation | 62840 | WebSocket |
| Pages | 37523 | WebSocket |

---

## Installation

### From Google Play Store (Recommended)

```bash
# Search for "ETS2LA Remote" on Google Play Store
# or visit: https://play.google.com/store/apps/...
```

### From GitHub Releases

1. Go to the [Releases Page](https://github.com/ARTEMKOPIK/ets2la-remote/releases)
2. Download the latest APK (`ets2la-remote-vX.X.X.apk`)
3. Enable "Install from unknown sources" in your device settings
4. Open the APK file and follow the installation prompts

### Building from Source

```bash
# Clone the repository
git clone https://github.com/ARTEMKOPIK/ets2la-remote.git
cd ets2la-remote

# Install Flutter dependencies
flutter pub get

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release
```

---

## Architecture

### Overview

The app follows a clean architecture pattern with clear separation of concerns:

```
lib/
├── main.dart                    # Application entry point
├── models/                      # Data models
│   ├── connection_profile.dart  # Connection profile storage
│   ├── telemetry.dart           # Navigation & position data
│   ├── trip_entry.dart          # Trip log entries
│   └── truck_state.dart         # Vehicle state data
├── providers/                   # State management (Provider)
│   ├── connection_provider.dart # Connection state
│   ├── settings_provider.dart   # App settings
│   ├── telemetry_provider.dart  # Real-time telemetry
│   └── update_provider.dart     # App updates
├── screens/                     # UI screens
│   ├── dashboard_screen.dart    # Main dashboard
│   ├── connect_screen.dart      # Server connection
│   ├── settings_screen.dart     # App settings
│   ├── app_settings_screen.dart # Advanced settings
│   ├── map_screen.dart          # Navigation map
│   ├── visualization_screen.dart# Unity visualization
│   ├── driver_mode_screen.dart  # Driver-focused UI
│   └── trip_log_screen.dart     # Trip history
├── services/                    # Business logic services
│   ├── websocket_service.dart   # WebSocket communication
│   ├── api_service.dart         # REST API client
│   ├── lan_discovery_service.dart # mDNS discovery
│   ├── port_probe_service.dart  # Port scanning
│   ├── navigation_ws_service.dart
│   ├── pages_ws_service.dart
│   ├── keep_alive_service.dart
│   ├── reconnect_backoff.dart
│   ├── wake_on_lan_service.dart
│   ├── vpn_detector.dart
│   ├── telemetry_feedback_service.dart
│   └── trip_log_service.dart
├── widgets/                     # Reusable UI components
│   ├── speed_gauge.dart         # Speed display
│   ├── autopilot_card.dart      # Autopilot controls
│   ├── metric_card.dart         # Telemetry cards
│   └── ...
└── theme/                       # App theming
    └── app_theme.dart           # Theme definitions
```

### State Management

The app uses **Provider** for state management with the following main providers:

1. **ConnectionProvider** — Manages WebSocket connection state, recent hosts, and profiles
2. **TelemetryProvider** — Handles real-time truck state and navigation data
3. **AppSettings** — Persists user preferences (theme, locale, ports, etc.)
4. **UpdateProvider** — Manages app update checks

### Key Services

- **WebSocketService** — Persistent WebSocket connection with auto-reconnect
- **ApiService** — REST API calls for plugin management
- **LanDiscoveryService** — mDNS/Bonjour discovery for automatic server detection
- **PortProbeService** — Parallel port scanning to identify available services

---

## WebSocket Protocol

The app communicates with the ETS2LA backend via WebSocket connections. The visualization socket sends JSON messages with truck telemetry data at approximately 20 Hz.

### Message Format

```json
{
  "channel": "truck",
  "data": {
    "speed": 85.5,
    "speedLimit": 90.0,
    "cruiseControlSpeed": 80.0,
    "targetSpeed": 80.0,
    "throttle": 0.75,
    "brake": 0.0,
    "indicatingLeft": false,
    "indicatingRight": true
  }
}
```

### Navigation Data

```json
{
  "channel": "navigation",
  "data": {
    "position": [longitude, latitude],
    "bearing": 45.0,
    "speedMph": 52.5
  }
}
```

---

## Configuration

### Default Ports

You can customize the ports in Settings > Ports (Advanced):

| Setting | Default | Description |
|---------|---------|-------------|
| API Port | 37520 | REST API for plugin queries |
| Visualization Port | 37522 | WebSocket for telemetry |
| Navigation Port | 62840 | WebSocket for GPS data |
| Pages Port | 37523 | WebSocket for plugin pages |

### Connection Profile

A connection profile contains:

- **Name** — Display name (e.g., "Home PC")
- **Host** — IP address or hostname (e.g., "192.168.1.100" or "ets2la-desktop.local")
- **MAC Address** — Optional, for Wake-on-LAN functionality
- **Favourite** — Mark as preferred for auto-connect

---

## Localization

The app supports the following languages:

| Language | Code | Status |
|----------|------|--------|
| English | en | Full support |
| Russian | ru | Full support |

Localization is handled via Flutter's `flutter_localizations` package with ARB files in the `lib/l10n/` directory.

---

## Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Development Setup

```bash
# Install Flutter SDK (version 3.0.0+)
# See: https://flutter.dev/docs/get-started/install

# Clone and setup
git clone https://github.com/ARTEMKOPIK/ets2la-remote.git
cd ets2la-remote
flutter pub get

# Run tests
flutter test

# Analyze code
flutter analyze
```

---

## License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- [ETS2LA](https://github.com/ETS2LA/Euro-Truck-Simulator-2-Lane-Assist) — The companion desktop application
- [Flutter](https://flutter.dev) — Cross-platform UI framework
- [OpenStreetMap](https://www.openstreetmap.org) — Map data provider
- Contributors and beta testers

---

<p align="center">
  Made with ❤️ for the Euro Truck Simulator 2 community
</p>