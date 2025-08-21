# 🚀 Developer Setup & Contribution Guide

## Quick Start

### Prerequisites

#### Required Software
- **Flutter SDK**: 3.6.0 or higher
  - Download from [flutter.dev](https://flutter.dev/docs/get-started/install)
  - Verify installation: `flutter doctor`
- **Dart SDK**: 3.6.0+ (included with Flutter)
- **Android Studio**: Latest stable version
  - Install Android SDK (API 21+)
  - Enable USB debugging on test device
- **VS Code** (recommended) with Flutter extensions

#### System Requirements
- **Windows 10/11**: PowerShell 5.1+
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 10GB free space for development tools
- **Android Device**: API 21+ or emulator

### Environment Setup

#### 1. Clone Repository
```bash
git clone https://github.com/dash-laifu/anchor.git
cd anchor
```

#### 2. Install Dependencies
```bash
flutter pub get
```

#### 3. Verify Setup
```bash
flutter doctor -v
```

Should show no errors for Flutter, Android toolchain, and connected devices.

#### 4. Run Development Build
```bash
# Using PowerShell script
.\scripts\run-debug.ps1

# Or directly
flutter run --debug
```

## Development Workflow

### Project Scripts

The project includes PowerShell scripts for common development tasks:

```powershell
# Development & Testing
.\scripts\run-debug.ps1      # Run debug build with hot reload
.\scripts\clean.ps1          # Clean build files and reset
.\scripts\install.ps1        # Install APK to connected device

# Production Builds
.\scripts\build.ps1          # Build release APK
.\scripts\build-debug.ps1    # Build debug APK

# Project Management
.\scripts\run.ps1           # Run release build
```

### Code Style & Standards

#### Flutter/Dart Guidelines
Follow the [official Dart style guide](https://dart.dev/guides/language/effective-dart/style):

```dart
// ✅ Good: Use meaningful names
final ParkingSpot currentSpot = await StorageService.getActiveSpot();

// ❌ Bad: Unclear abbreviations
final ps = await StorageService.getAS();

// ✅ Good: Clear function structure
Future<void> saveSpotWithPhoto({
  required Position position,
  String? note,
  String? levelOrSpot,
}) async {
  // Implementation
}

// ✅ Good: Proper error handling
try {
  await LocationService.getCurrentLocation();
} catch (e) {
  Logger.d('Location error: $e');
  // Handle gracefully
}
```

#### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `ParkingSpot`, `LocationService` |
| Methods | camelCase | `getCurrentLocation()`, `saveSpot()` |
| Variables | camelCase | `currentSpot`, `isLoading` |
| Constants | camelCase | `maxHistorySpots`, `locationTimeout` |
| Files | snake_case | `parking_spot.dart`, `location_service.dart` |
| Private | _prefixed | `_database`, `_loadData()` |

#### Documentation Standards

```dart
/// Service for handling GPS location and geocoding operations.
/// 
/// This service manages location permissions, GPS acquisition,
/// and reverse geocoding with proper error handling and timeouts.
class LocationService {
  /// Gets the current GPS location with a 6-second timeout.
  /// 
  /// Returns null if permissions are denied or GPS fails.
  /// Throws [LocationServiceDisabledException] if GPS is disabled.
  static Future<Position?> getCurrentLocation() async {
    // Implementation
  }
}
```

### Git Workflow

#### Branch Strategy
```bash
main                    # Production-ready code
├── feature/new-feature # New features
├── bugfix/fix-issue   # Bug fixes
└── hotfix/urgent-fix  # Emergency fixes
```

#### Commit Guidelines
Use [Conventional Commits](https://www.conventionalcommits.org/) format:

```bash
# Features
git commit -m "feat: add photo capture to parking spots"
git commit -m "feat(ui): implement dark mode theme"

# Bug fixes
git commit -m "fix: resolve GPS timeout on slow networks"
git commit -m "fix(android): fix notification permissions on API 33+"

# Documentation
git commit -m "docs: update API documentation"
git commit -m "docs(readme): add troubleshooting section"

# Refactoring
git commit -m "refactor: extract storage service methods"
git commit -m "style: apply consistent formatting"
```

#### Pull Request Process
1. **Create Feature Branch**
   ```bash
   git checkout -b feature/parking-reminders
   ```

2. **Make Changes**
   - Write clean, documented code
   - Add tests where appropriate
   - Follow style guidelines

3. **Test Thoroughly**
   ```bash
   flutter test                    # Run unit tests
   flutter analyze                 # Static analysis
   .\scripts\build.ps1            # Verify builds
   ```

4. **Submit PR**
   - Clear description of changes
   - Link to relevant issues
   - Screenshots for UI changes
   - Test results and device compatibility

## Testing Guidelines

### Unit Testing

#### Service Layer Tests
```dart
// test/services/storage_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:anchor/services/storage_service.dart';
import 'package:anchor/models/parking_spot.dart';

void main() {
  group('StorageService', () {
    setUpAll(() async {
      // Initialize test database
    });

    test('should save and retrieve active parking spot', () async {
      // Arrange
      final spot = ParkingSpot(
        id: 'test-id',
        createdAt: DateTime.now(),
        latitude: 37.7749,
        longitude: -122.4194,
        accuracyMeters: 15.0,
        isActive: true,
      );

      // Act
      await StorageService.saveParkingSpot(spot);
      final retrieved = await StorageService.getActiveSpot();

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(spot.id));
      expect(retrieved.isActive, isTrue);
    });

    test('should deactivate previous spot when saving new active spot', () async {
      // Test implementation
    });
  });
}
```

#### Widget Testing
```dart
// test/widgets/primary_action_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anchor/widgets/primary_action_button.dart';

void main() {
  testWidgets('PrimaryActionButton displays correct text when no spot saved', 
    (WidgetTester tester) async {
    // Arrange
    bool wasPressed = false;

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryActionButton(
            hasActiveSpot: false,
            onPressed: () => wasPressed = true,
            isLoading: false,
          ),
        ),
      ),
    );

    // Assert
    expect(find.text('Save Parking Spot'), findsOneWidget);
    expect(find.byIcon(Icons.local_parking), findsOneWidget);

    // Test interaction
    await tester.tap(find.byType(PrimaryActionButton));
    expect(wasPressed, isTrue);
  });
}
```

### Integration Testing

#### End-to-End Scenarios
```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:anchor/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Parking App E2E Tests', () {
    testWidgets('complete save and navigate flow', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Tap save button
      await tester.tap(find.byType(PrimaryActionButton));
      await tester.pumpAndSettle();

      // Fill in parking details
      await tester.enterText(find.byKey(Key('note_field')), 'Level 2 near elevator');
      await tester.tap(find.text('Save Spot'));
      await tester.pumpAndSettle();

      // Verify spot is saved
      expect(find.text('Navigate to Car'), findsOneWidget);
      
      // Test navigation
      await tester.tap(find.byType(PrimaryActionButton));
      await tester.pumpAndSettle();
      
      // Should show navigation options
      expect(find.text('Choose Navigation App'), findsOneWidget);
    });
  });
}
```

### Manual Testing Checklist

#### Core Functionality
- [ ] **Save Spot**: GPS acquisition, photo capture, notes
- [ ] **Navigation**: External app launch, walking directions
- [ ] **History**: View past spots, search functionality
- [ ] **Settings**: Preferences, debug options
- [ ] **Permissions**: Location, camera, notifications

#### Device Compatibility
- [ ] **Android Versions**: API 21, 26, 30, 33+
- [ ] **Screen Sizes**: Phone, tablet, foldable
- [ ] **Performance**: Low-end devices, battery optimization
- [ ] **Offline**: Airplane mode, poor GPS signal

#### Edge Cases
- [ ] **GPS Issues**: Indoor parking, weak signal, permission denied
- [ ] **Storage**: Full device storage, corrupted database
- [ ] **Notifications**: Do not disturb, battery optimization
- [ ] **Upgrades**: App updates, data migration

## Debugging & Troubleshooting

### Debug Configuration

#### Enable Debug Features
```dart
// lib/config/debug_config.dart
class DebugConfig {
  static const bool enableNotificationTesting = true;
  static const bool enableDetailedLogging = true;
  static const bool showDebugSettingsSection = true;
  static const bool skipPermissionChecks = false; // Only for testing
}
```

#### Debug Logging
```dart
// lib/utils/logger.dart
class Logger {
  static void d(String message) {
    if (kDebugMode) {
      print('[DEBUG] ${DateTime.now()}: $message');
    }
  }
  
  static void e(String message, [Object? error]) {
    print('[ERROR] ${DateTime.now()}: $message');
    if (error != null) {
      print('[ERROR] Stack trace: $error');
    }
  }
}

// Usage throughout app
Logger.d('LocationService: GPS accuracy = ${position.accuracy}m');
Logger.e('StorageService: Failed to save spot', error);
```

### Common Issues & Solutions

#### GPS Not Working
```dart
// Debug GPS issues
Future<void> debugLocationIssues() async {
  Logger.d('=== GPS DEBUG SESSION ===');
  
  // Check service enabled
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  Logger.d('Location service enabled: $serviceEnabled');
  
  // Check permissions
  final permission = await Geolocator.checkPermission();
  Logger.d('Location permission: $permission');
  
  // Try to get location
  try {
    final position = await Geolocator.getCurrentPosition();
    Logger.d('GPS success: ${position.latitude}, ${position.longitude}');
    Logger.d('GPS accuracy: ${position.accuracy}m');
  } catch (e) {
    Logger.e('GPS failed', e);
  }
}
```

#### Database Issues
```dart
// Debug database state
Future<void> debugDatabase() async {
  final db = await StorageService.database;
  
  // Check tables
  final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
  Logger.d('Database tables: $tables');
  
  // Check spot count
  final spotCount = await db.rawQuery('SELECT COUNT(*) as count FROM parking_spots');
  Logger.d('Total spots: ${spotCount.first['count']}');
  
  // Check active spots
  final activeSpots = await db.query('parking_spots', where: 'is_active = 1');
  Logger.d('Active spots: ${activeSpots.length}');
}
```

#### Notification Issues
```dart
// Test notification system
Future<void> debugNotifications() async {
  Logger.d('=== NOTIFICATION DEBUG ===');
  
  // Check permissions
  final canScheduleExact = await NativeAlarmService.canScheduleExactAlarms();
  Logger.d('Can schedule exact alarms: $canScheduleExact');
  
  // Test immediate notification
  try {
    await NotificationService.showImmediate(
      id: 999,
      title: 'Debug Test',
      body: 'If you see this, notifications work!',
    );
    Logger.d('Immediate notification sent successfully');
  } catch (e) {
    Logger.e('Immediate notification failed', e);
  }
  
  // Test scheduled notification
  try {
    await NotificationService.scheduleReminder(
      id: 998,
      title: 'Debug Reminder',
      body: 'Scheduled notification test',
      scheduledTime: DateTime.now().add(Duration(minutes: 1)),
    );
    Logger.d('Scheduled notification set successfully');
  } catch (e) {
    Logger.e('Scheduled notification failed', e);
  }
}
```

### Performance Profiling

#### Memory Usage
```bash
# Monitor memory usage during development
flutter run --profile
# Use Flutter Inspector in IDE to monitor widget rebuilds
```

#### Database Performance
```dart
// Profile database queries
Future<void> profileDatabaseQueries() async {
  final stopwatch = Stopwatch()..start();
  
  final spots = await StorageService.getHistorySpots(limit: 50);
  
  stopwatch.stop();
  Logger.d('Query took: ${stopwatch.elapsedMilliseconds}ms for ${spots.length} spots');
}
```

#### Build Analysis
```bash
# Analyze app size
flutter build apk --analyze-size

# Check for unused dependencies
flutter deps
```

## CI/CD Pipeline

### Automated Testing
```yaml
# .github/workflows/test.yml (if using GitHub Actions)
name: Test
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.6.0'
    - run: flutter pub get
    - run: flutter analyze
    - run: flutter test
```

### Build Automation
```powershell
# scripts/ci-build.ps1
param(
    [string]$Version = "1.0.0"
)

Write-Host "Building Anchor v$Version"

# Clean and prepare
flutter clean
flutter pub get

# Run tests
Write-Host "Running tests..."
flutter test
if ($LASTEXITCODE -ne 0) {
    Write-Error "Tests failed"
    exit 1
}

# Static analysis
Write-Host "Running analysis..."
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Error "Analysis failed"
    exit 1
}

# Build release
Write-Host "Building release APK..."
flutter build apk --release --obfuscate --split-debug-info=build/symbols

Write-Host "Build completed successfully"
```

## Security Considerations

### Code Security

#### Secrets Management
```dart
// ❌ Never commit secrets
const String API_KEY = "sk-1234567890abcdef"; // DON'T DO THIS

// ✅ Use environment variables or secure storage
final apiKey = Platform.environment['API_KEY'] ?? '';
```

#### Input Validation
```dart
// Always validate user input
Future<void> saveNote(String userNote) async {
  // Sanitize input
  final cleanNote = userNote.trim();
  if (cleanNote.length > 500) {
    throw ArgumentError('Note too long');
  }
  
  // Escape for database
  await StorageService.updateSpotNote(spotId, cleanNote);
}
```

#### Permission Handling
```dart
// Request permissions appropriately
Future<bool> requestLocationPermission() async {
  if (await Permission.location.isGranted) {
    return true;
  }
  
  // Show rationale before requesting
  if (await Permission.location.shouldShowRequestRationale) {
    await _showLocationRationale();
  }
  
  final status = await Permission.location.request();
  return status.isGranted;
}
```

### Privacy Compliance

#### Data Minimization
```dart
// Only store necessary data
class ParkingSpot {
  // ✅ Essential data
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  
  // ❌ Avoid storing
  // final String deviceId;
  // final String userIdentifier;
}
```

#### Local Storage Only
```dart
// Ensure no data leaves device
class StorageService {
  // ✅ Local SQLite only
  static Future<Database> get database async {
    final path = join(await getDatabasesPath(), 'parking_spots.db');
    return openDatabase(path, version: 1);
  }
  
  // ❌ Avoid cloud sync without explicit user consent
  // static Future<void> syncToCloud() async { ... }
}
```

## Release Process

### Pre-Release Checklist

#### Code Quality
- [ ] All tests passing
- [ ] No analyzer warnings
- [ ] Code reviewed and approved
- [ ] Documentation updated
- [ ] Changelog updated

#### Testing
- [ ] Manual testing on multiple devices
- [ ] GPS accuracy tested in various environments
- [ ] Notification reliability verified
- [ ] Permission flows tested
- [ ] Offline functionality confirmed

#### Security
- [ ] No hardcoded secrets
- [ ] Proper permission handling
- [ ] Input validation in place
- [ ] Privacy compliance verified

### Version Bumping
```bash
# Update version in pubspec.yaml
version: 1.0.1+2

# Tag release
git tag v1.0.1
git push origin v1.0.1
```

### Build Release
```bash
# Build signed release
flutter build apk --release --obfuscate --split-debug-info=build/symbols

# Or app bundle for Play Store
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```

## Support & Resources

### Documentation
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Material Design 3](https://m3.material.io/)
- [Android Developer Guide](https://developer.android.com/guide)

### Community
- [Flutter Community](https://flutter.dev/community)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
- [Flutter Discord](https://discord.gg/flutter)

### Tools
- [Flutter Inspector](https://flutter.dev/docs/development/tools/flutter-inspector)
- [Dart DevTools](https://dart.dev/tools/dart-devtools)
- [Android Studio](https://developer.android.com/studio)
- [VS Code Flutter Extension](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)

---

## Need Help?

### Getting Started Issues
1. **Check Prerequisites**: Ensure Flutter and Android SDK are properly installed
2. **Run Flutter Doctor**: `flutter doctor -v` should show no errors
3. **Check Dependencies**: `flutter pub get` should complete without errors
4. **Device Connection**: Ensure Android device is connected and debugging enabled

### Development Questions
1. **Review Architecture**: Check `docs/ARCHITECTURE.md` for design patterns
2. **Check Examples**: Look at existing code for similar functionality
3. **Run Tests**: `flutter test` to verify your changes don't break existing functionality
4. **Debug Mode**: Use `Logger.d()` for troubleshooting

### Contributing
1. **Read Style Guide**: Follow established coding conventions
2. **Test Thoroughly**: Ensure changes work on multiple devices
3. **Document Changes**: Update relevant documentation
4. **Submit PR**: Provide clear description of changes and testing performed

Happy coding! 🚀
