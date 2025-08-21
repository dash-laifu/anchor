# 🚗 Anchor - Never Lose Your Car Again

<div align="center">

![Anchor Logo](https://img.shields.io/badge/Anchor-Parking%20Saver-2E7D32?style=for-the-badge&logo=car&logoColor=white)

**A dead-simple, privacy-first parking spot saver that works offline**

[![Flutter](https://img.shields.io/badge/Flutter-3.6.0+-02569B?style=flat&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.6.0+-0175C2?style=flat&logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Private-red?style=flat)](LICENSE)

[Features](#-features) • [Quick Start](#-quick-start) • [Architecture](#-architecture) • [Privacy](#-privacy) • [Contributing](#-contributing)

</div>

---

## 📱 About

Anchor is a Flutter mobile application designed to solve one simple problem: **never lose your car in a parking lot again**. With one tap, save your parking location with GPS coordinates, photos, and notes. Navigate back effortlessly using your preferred navigation app, all while keeping your data completely private and offline.

### 🎯 Core Philosophy
- **One-tap simplicity**: Save and navigate with minimal interaction
- **Privacy-first**: All data stored locally on your device
- **Offline-capable**: Works without internet connection
- **GPS-smart**: Intelligent accuracy feedback and graceful degradation

---

## ✨ Features

### 🅿️ Core Parking Features
- **One-Tap Save**: Large, prominent button to instantly save your parking spot
- **Smart GPS Accuracy**: Visual feedback on location precision (High/Medium/Low)
- **Photo Capture**: Take photos to help identify your parking spot
- **Notes & Location Details**: Add floor levels, section names, or any helpful notes
- **Single Active Spot**: Only one active parking spot at a time (auto-archives previous)

### 🧭 Navigation & Reminders
- **External Navigation**: Launch Google Maps, Apple Maps, or other navigation apps
- **Walking Directions**: Optimized for pedestrian navigation back to your car
- **Time-based Reminders**: Set notifications for parking meter expiration
- **Native Android Alarms**: Reliable notifications using AlarmManager

### 📊 History & Management
- **Parking History**: View up to 50 recent parking spots
- **Search & Filter**: Find specific parking sessions by location or notes
- **Time Tracking**: See how long ago you parked
- **Cleanup**: Automatic cleanup of old parking records

### 🔒 Privacy & Data
- **Local-Only Storage**: No cloud sync, no external servers
- **SQLite Database**: Efficient local data persistence
- **Media Management**: Photos stored locally in app directory
- **Data Export**: Export your parking history for backup

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.6.0 or higher
- Dart 3.6.0 or higher
- Android Studio / VS Code with Flutter extensions
- Android device or emulator (API level 21+)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/dash-laifu/anchor.git
   cd anchor
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Build Scripts

The project includes PowerShell scripts for common tasks:

```bash
# Development build and run
.\scripts\run-debug.ps1

# Production build
.\scripts\build.ps1

# Clean project
.\scripts\clean.ps1

# Install to device
.\scripts\install.ps1
```

---

## 🏗️ Architecture

### Project Structure
```
lib/
├── main.dart                 # App entry point and MaterialApp setup
├── theme.dart               # Light/dark theme definitions
├── models/
│   └── parking_spot.dart    # Core data models (ParkingSpot, MediaAsset, AppSettings)
├── services/
│   ├── location_service.dart     # GPS handling and geocoding
│   ├── storage_service.dart      # Local database and preferences
│   ├── notification_service.dart # Reminders and alerts
│   └── native_alarm_service.dart # Android AlarmManager integration
├── screens/
│   ├── home_screen.dart     # Main interface with save/navigate actions
│   ├── history_screen.dart  # Parking history and search
│   └── settings_screen.dart # App configuration and preferences
├── widgets/
│   ├── primary_action_button.dart # Main save/navigate button
│   ├── current_spot_card.dart     # Active parking spot display
│   ├── save_spot_sheet.dart       # Bottom sheet for saving spots
│   └── notification_test_widget.dart # Debug notification testing
└── utils/
    └── logger.dart          # Debug logging utilities
```

### Key Components

#### 🎯 State Management
- **Simple setState**: No complex state management, uses Flutter's built-in state
- **Service Layer**: Business logic separated into service classes
- **Local Storage**: SQLite for structured data, SharedPreferences for settings

#### 📡 Services Architecture
- **LocationService**: GPS permissions, accuracy assessment, reverse geocoding
- **StorageService**: Database operations, media file management, settings persistence
- **NotificationService**: Reminder scheduling, native alarm integration
- **Native Integration**: Android-specific AlarmManager for reliable notifications

#### 🎨 UI/UX Design
- **Material Design 3**: Modern Material You design system
- **Responsive Layout**: Adapts to different screen sizes
- **Accessibility**: Proper semantics and contrast ratios
- **Theme Support**: Full light/dark mode support

---

## 🗄️ Data Models

### ParkingSpot
Core data structure representing a saved parking location:

```dart
class ParkingSpot {
  final String id;                    // Unique identifier
  final DateTime createdAt;           // When the spot was saved
  final double latitude;              // GPS latitude
  final double longitude;             // GPS longitude
  final double accuracyMeters;        // GPS accuracy in meters
  final String? address;              // Reverse-geocoded address
  final String? note;                 // User notes
  final String? levelOrSpot;          // Floor/section information
  final List<String> mediaIds;       // Associated photos
  final DateTime? reminderAt;         // Optional reminder time
  final SaveSource source;            // How the spot was saved
  final bool isActive;                // Currently active spot
}
```

### GPS Accuracy Levels
- **High (≤25m)**: Excellent GPS signal, precise location
- **Medium (26-75m)**: Good GPS signal, reliable location
- **Low (>75m)**: Weak GPS signal, may need additional context (photos/notes)

### Save Sources
- **Manual**: User explicitly saved the spot
- **BT Disconnect**: Auto-saved when Bluetooth disconnects
- **CarPlay Disconnect**: Auto-saved when CarPlay disconnects
- **SSID Disconnect**: Auto-saved when leaving specific WiFi network

---

## 🔧 Dependencies

### Core Flutter Packages
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter` | SDK | Core Flutter framework |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |
| `google_fonts` | ^6.1.0 | Typography (Inter font) |

### Location & Navigation
| Package | Version | Purpose |
|---------|---------|---------|
| `geolocator` | ^13.0.4 | GPS location services |
| `geocoding` | ^4.0.0 | Address lookup from coordinates |
| `url_launcher` | ^6.0.0 | Launch external navigation apps |

### Storage & Data
| Package | Version | Purpose |
|---------|---------|---------|
| `sqflite` | ^2.0.0 | Local SQLite database |
| `shared_preferences` | ^2.0.0 | Settings and preferences |
| `path_provider` | ^2.0.0 | File system access |

### Media & Notifications
| Package | Version | Purpose |
|---------|---------|---------|
| `image_picker` | >=1.1.2 | Camera integration for photos |
| `flutter_local_notifications` | ^19.0.0 | Local notification system |
| `device_info_plus` | ^9.0.0 | Device information |
| `permission_handler` | ^11.0.0 | Runtime permissions |

### Utilities
| Package | Version | Purpose |
|---------|---------|---------|
| `intl` | 0.20.2 | Internationalization and date formatting |

---

## 📱 Permissions

### Android Permissions Required
```xml
<!-- Location (required) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Camera for photos (optional) -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- Notifications (required for reminders) -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />

<!-- File storage (required for photos) -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### Permission Handling
- **Location**: Requested on first app launch with clear explanation
- **Camera**: Requested when user attempts to take a photo
- **Exact Alarms**: Requested when user sets a reminder
- **Graceful Degradation**: App functions with limited permissions

---

## 🔒 Privacy & Security

### Data Storage Philosophy
Anchor is built with **privacy-first** principles:

- ✅ **100% Local Storage**: No data ever leaves your device
- ✅ **No Account Required**: No sign-up, no login, no tracking
- ✅ **No Internet Dependency**: Works completely offline
- ✅ **No Analytics**: No usage tracking or telemetry
- ✅ **Media Privacy**: Photos stored locally in app sandbox

### What Data is Stored
| Data Type | Storage Location | Purpose |
|-----------|------------------|---------|
| GPS Coordinates | Local SQLite DB | Finding your car |
| Photos | App documents directory | Visual identification |
| Addresses | Local SQLite DB | User-friendly location names |
| Notes | Local SQLite DB | Additional context |
| Settings | SharedPreferences | App configuration |

### Data Export & Backup
Users can export their parking history for backup purposes:
- JSON format with all parking data
- Includes coordinates, timestamps, notes
- Photos can be manually backed up from device storage

---

## 🧪 Testing & Debugging

### Debug Features
The app includes built-in testing widgets for development:

```dart
// Access via Settings screen (debug builds only)
NotificationTestWidget.show(context)
```

### Debug Logging
Comprehensive logging system for troubleshooting:
- Location accuracy issues
- Notification scheduling
- Database operations
- Permission handling

### Test Notifications
- Immediate notification test
- Scheduled reminder test (1, 5, 30 minutes)
- Native Android alarm test
- Notification permission verification

---

## 🎨 Theming & Design

### Color Scheme
| Element | Light Mode | Dark Mode | Purpose |
|---------|------------|-----------|---------|
| Primary | Deep Green (#2E7D32) | Light Green (#81C784) | Parking/location theme |
| Secondary | Navigation Blue (#1976D2) | Light Blue (#64B5F6) | Navigation actions |
| Tertiary | Accent Orange (#FF6B35) | Light Orange (#FF8A65) | Warnings/alerts |

### Typography
- **Font Family**: Inter (Google Fonts)
- **Responsive Sizing**: Adapts to system font size preferences
- **Accessibility**: High contrast ratios, proper semantic hierarchy

### Material Design 3
- Modern Material You design principles
- Dynamic color support (where available)
- Consistent elevation and spacing
- Proper touch targets and accessibility

---

## 🔄 State Management

### Architecture Pattern
Anchor uses a simple, straightforward state management approach:

```dart
// Service Layer Pattern
LocationService.getCurrentLocation() → Position
StorageService.saveParkingSpot() → Database
NotificationService.scheduleReminder() → Native Alarm

// UI State
setState() → Widget rebuilds
```

### Data Flow
1. **User Action** → UI Widget
2. **Widget** → Service Layer
3. **Service** → Local Storage/Device APIs
4. **Result** → UI Update via setState()

This approach ensures:
- ✅ Simple debugging and testing
- ✅ Clear separation of concerns
- ✅ Minimal dependencies
- ✅ Easy maintenance

---

## 🚀 Performance

### Optimizations
- **Lazy Loading**: History loaded on demand
- **Image Compression**: Photos optimized for storage
- **Database Indexing**: Fast queries on frequently accessed data
- **Memory Management**: Proper widget lifecycle management

### Storage Limits
- **Maximum History**: 50 parking spots (auto-cleanup)
- **Photo Compression**: Max 1200px width
- **Database Size**: Typically <10MB for full history

### Battery Optimization
- **Background Limits**: No background location tracking
- **Efficient GPS**: Quick location acquisition with timeout
- **Native Alarms**: Uses Android AlarmManager for minimal battery impact

---

## 🧭 Navigation Integration

### Supported Navigation Apps
- **Google Maps** (Default)
- **Apple Maps** (iOS devices)
- **Any navigation app** that supports standard coordinate URLs

### Navigation URLs
```dart
// Google Maps
https://www.google.com/maps/dir/?api=1&destination=LAT,LON&travelmode=walking

// Apple Maps
http://maps.apple.com/?daddr=LAT,LON&dirflg=w
```

### Walking Optimization
- Directions optimized for pedestrian navigation
- Accounts for walking paths and shortcuts
- Provides estimated walking time

---

## 🔧 Development

### Code Quality
- **Flutter Lints**: Enforced coding standards
- **Type Safety**: Full null safety implementation
- **Documentation**: Comprehensive inline documentation
- **Error Handling**: Graceful error handling throughout

### Build Configuration
```yaml
# pubspec.yaml
environment:
  sdk: ^3.6.0

flutter:
  uses-material-design: true
```

### Platform-Specific Code
- **Native Android**: AlarmManager integration for reliable notifications
- **Kotlin Integration**: Native alarm service implementation
- **Permission Handling**: Platform-appropriate permission requests

---

## 📝 Configuration

### App Settings
Users can configure:
- **Distance Units**: Kilometers or miles
- **Default Navigation App**: Google Maps, Apple Maps, or ask each time
- **Reminder Duration**: Default parking duration for quick setup
- **Accuracy Hints**: Show/hide GPS accuracy guidance
- **Privacy Mode**: Local-only data storage (always enabled)

### Debug Configuration
```dart
// lib/config/debug_config.dart
class DebugConfig {
  static const bool enableNotificationTesting = true;
  static const bool enableDetailedLogging = true;
  static const bool showDebugSettingsSection = true;
}
```

---

## 🤝 Contributing

### Development Setup
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Install dependencies: `flutter pub get`
4. Make your changes
5. Test thoroughly on multiple devices
6. Commit: `git commit -m 'Add amazing feature'`
7. Push: `git push origin feature/amazing-feature`
8. Create a Pull Request

### Code Style
- Follow [Flutter style guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Add documentation for public APIs
- Ensure null safety compliance

### Testing Guidelines
- Test on multiple Android versions
- Verify GPS accuracy in different environments
- Test notification reliability
- Validate privacy requirements

---

## 🐛 Troubleshooting

### Common Issues

#### GPS Not Working
- **Check Permissions**: Ensure location permissions are granted
- **Location Services**: Verify GPS is enabled on device
- **Indoor Locations**: GPS may be inaccurate indoors
- **Solution**: Take a photo or add notes for indoor parking

#### Notifications Not Showing
- **Exact Alarm Permission**: Required on Android 12+
- **Battery Optimization**: Disable for Anchor app
- **Do Not Disturb**: May block notifications
- **Solution**: Check notification settings and permissions

#### App Crashes
- **Storage Space**: Ensure sufficient device storage
- **Permissions**: Grant all required permissions
- **Restart**: Try restarting the app
- **Solution**: Clear app data if issues persist

#### Photos Not Saving
- **Camera Permission**: Ensure camera access is granted
- **Storage Permission**: Required for saving photos
- **Storage Space**: Check available device storage
- **Solution**: Grant permissions and free up storage space

---

## 📄 License

This project is proprietary software. All rights reserved.

---

## 🏆 Acknowledgments

- **Flutter Team**: For the amazing cross-platform framework
- **Material Design**: For the beautiful design system
- **Community**: For the excellent packages and resources

---

<div align="center">

**Built with ❤️ using Flutter**

*Never lose your car again with Anchor*

</div>
