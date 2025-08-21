# 📚 API Reference Documentation

## Overview

This document provides comprehensive API documentation for the Anchor parking app's core services, models, and utilities. The app is built using a service-oriented architecture with clear separation between UI, business logic, and data layers.

## Table of Contents

- [Core Services](#core-services)
  - [LocationService](#locationservice)
  - [StorageService](#storageservice)
  - [NotificationService](#notificationservice)
  - [NativeAlarmService](#nativealarmservice)
- [Data Models](#data-models)
  - [ParkingSpot](#parkingspot)
  - [MediaAsset](#mediaasset)
  - [AppSettings](#appsettings)
- [Utilities](#utilities)
  - [Logger](#logger)
- [Enums & Constants](#enums--constants)

---

## Core Services

### LocationService

Handles GPS location acquisition, permission management, and geocoding operations.

**File**: `lib/services/location_service.dart`

#### Static Methods

##### `checkPermissions()`
```dart
static Future<bool> checkPermissions()
```
Checks if location permissions are granted and location services are enabled.

**Returns**: `Future<bool>` - `true` if permissions are granted and services enabled

**Example**:
```dart
final hasPermission = await LocationService.checkPermissions();
if (!hasPermission) {
  // Handle permission denied
}
```

---

##### `getCurrentLocation()`
```dart
static Future<Position?> getCurrentLocation()
```
Acquires current GPS position with 6-second timeout and high accuracy.

**Returns**: `Future<Position?>` - GPS position or `null` if failed

**Throws**:
- `LocationServiceDisabledException` - GPS services disabled
- `PermissionDeniedException` - Location permission denied
- `TimeoutException` - GPS acquisition timeout

**Example**:
```dart
try {
  final position = await LocationService.getCurrentLocation();
  if (position != null) {
    print('Location: ${position.latitude}, ${position.longitude}');
    print('Accuracy: ${position.accuracy}m');
  }
} catch (e) {
  Logger.e('Location error: $e');
}
```

---

##### `reverseGeocode()`
```dart
static Future<String?> reverseGeocode(double latitude, double longitude)
```
Converts GPS coordinates to human-readable address.

**Parameters**:
- `latitude` (double): GPS latitude coordinate
- `longitude` (double): GPS longitude coordinate

**Returns**: `Future<String?>` - Address string or `null` if failed

**Example**:
```dart
final address = await LocationService.reverseGeocode(37.7749, -122.4194);
print(address); // "123 Main St, San Francisco, CA"
```

---

##### `getAccuracyLevel()`
```dart
static ParkingLocationAccuracy getAccuracyLevel(double accuracyMeters)
```
Classifies GPS accuracy into High/Medium/Low categories.

**Parameters**:
- `accuracyMeters` (double): GPS accuracy in meters

**Returns**: `ParkingLocationAccuracy` enum value

**Classification**:
- High: ≤25 meters
- Medium: 26-75 meters  
- Low: >75 meters

**Example**:
```dart
final accuracy = LocationService.getAccuracyLevel(15.0);
print(accuracy); // ParkingLocationAccuracy.high
```

---

##### `launchNavigation()`
```dart
static Future<String> launchNavigation(
  double latitude,
  double longitude,
  String? preferredApp,
)
```
Generates navigation URL for external navigation apps.

**Parameters**:
- `latitude` (double): Destination latitude
- `longitude` (double): Destination longitude
- `preferredApp` (String?): Preferred navigation app ('apple_maps' or null for Google Maps)

**Returns**: `Future<String>` - Navigation URL

**Example**:
```dart
final url = await LocationService.launchNavigation(37.7749, -122.4194, null);
// Returns: "https://www.google.com/maps/dir/?api=1&destination=37.7749,-122.4194&travelmode=walking"
```

---

### StorageService

Manages local SQLite database operations, settings persistence, and media file handling.

**File**: `lib/services/storage_service.dart`

#### Properties

```dart
static const int maxHistorySpots = 50;
```
Maximum number of historical parking spots to retain.

#### Database Operations

##### `saveParkingSpot()`
```dart
static Future<void> saveParkingSpot(ParkingSpot spot)
```
Saves a parking spot to the database. Automatically deactivates previous active spots.

**Parameters**:
- `spot` (ParkingSpot): Parking spot to save

**Side Effects**:
- Deactivates existing active spots if new spot is active
- Triggers cleanup of old spots if history exceeds limit

**Example**:
```dart
final spot = ParkingSpot(
  id: 'spot_${DateTime.now().millisecondsSinceEpoch}',
  createdAt: DateTime.now(),
  latitude: 37.7749,
  longitude: -122.4194,
  accuracyMeters: 15.0,
  isActive: true,
);
await StorageService.saveParkingSpot(spot);
```

---

##### `getActiveSpot()`
```dart
static Future<ParkingSpot?> getActiveSpot()
```
Retrieves the currently active parking spot.

**Returns**: `Future<ParkingSpot?>` - Active spot or `null` if none

**Example**:
```dart
final activeSpot = await StorageService.getActiveSpot();
if (activeSpot != null) {
  print('Current spot: ${activeSpot.address}');
}
```

---

##### `getHistorySpots()`
```dart
static Future<List<ParkingSpot>> getHistorySpots({
  int limit = 20,
  String? searchQuery,
})
```
Retrieves historical (inactive) parking spots with optional search filtering.

**Parameters**:
- `limit` (int): Maximum number of spots to return (default: 20)
- `searchQuery` (String?): Optional search term for notes, address, or level

**Returns**: `Future<List<ParkingSpot>>` - List of historical spots, newest first

**Example**:
```dart
// Get recent history
final recentSpots = await StorageService.getHistorySpots(limit: 10);

// Search history
final mallSpots = await StorageService.getHistorySpots(
  searchQuery: 'mall',
  limit: 50,
);
```

---

##### `deleteSpot()`
```dart
static Future<void> deleteSpot(String spotId)
```
Deletes a parking spot and associated media files.

**Parameters**:
- `spotId` (String): Unique identifier of spot to delete

**Side Effects**:
- Removes spot from database
- Deletes associated photos from file system
- Removes media asset records

**Example**:
```dart
await StorageService.deleteSpot('spot_1234567890');
```

---

##### `deactivateCurrentSpot()`
```dart
static Future<void> deactivateCurrentSpot()
```
Marks the currently active spot as inactive (e.g., when user arrives at car).

**Example**:
```dart
await StorageService.deactivateCurrentSpot();
```

---

##### `updateSpotAddress()`
```dart
static Future<void> updateSpotAddress(String spotId, String address)
```
Updates the address field of an existing parking spot.

**Parameters**:
- `spotId` (String): Spot identifier
- `address` (String): Human-readable address

**Example**:
```dart
await StorageService.updateSpotAddress('spot_123', '123 Main St, San Francisco, CA');
```

---

#### Media Operations

##### `saveMediaAsset()`
```dart
static Future<void> saveMediaAsset(MediaAsset asset)
```
Saves a media asset (photo) record to the database.

**Parameters**:
- `asset` (MediaAsset): Media asset to save

**Example**:
```dart
final mediaAsset = MediaAsset(
  id: 'media_${DateTime.now().millisecondsSinceEpoch}',
  spotId: 'spot_123',
  type: 'photo',
  localPath: '/path/to/photo.jpg',
  createdAt: DateTime.now(),
);
await StorageService.saveMediaAsset(mediaAsset);
```

---

##### `getMediaForSpot()`
```dart
static Future<List<MediaAsset>> getMediaForSpot(String spotId)
```
Retrieves all media assets associated with a parking spot.

**Parameters**:
- `spotId` (String): Parking spot identifier

**Returns**: `Future<List<MediaAsset>>` - List of media assets

**Example**:
```dart
final photos = await StorageService.getMediaForSpot('spot_123');
for (final photo in photos) {
  print('Photo: ${photo.localPath}');
}
```

---

##### `getMediaDirectory()`
```dart
static Future<String> getMediaDirectory()
```
Gets the directory path for storing media files, creating it if needed.

**Returns**: `Future<String>` - Absolute path to media directory

**Example**:
```dart
final mediaDir = await StorageService.getMediaDirectory();
final photoPath = path.join(mediaDir, 'spot_123_photo.jpg');
```

---

#### Settings Operations

##### `saveSettings()`
```dart
static Future<void> saveSettings(AppSettings settings)
```
Persists app settings to SharedPreferences.

**Parameters**:
- `settings` (AppSettings): Settings object to save

**Example**:
```dart
final settings = AppSettings(
  distanceUnit: 'km',
  showAccuracyHints: true,
  defaultNavigationApp: 'google_maps',
);
await StorageService.saveSettings(settings);
```

---

##### `getSettings()`
```dart
static Future<AppSettings> getSettings()
```
Retrieves app settings from SharedPreferences.

**Returns**: `Future<AppSettings>` - Current app settings with defaults

**Example**:
```dart
final settings = await StorageService.getSettings();
print('Distance unit: ${settings.distanceUnit}');
```

---

#### Data Management

##### `exportData()`
```dart
static Future<Map<String, dynamic>> exportData()
```
Exports all app data for backup purposes.

**Returns**: `Future<Map<String, dynamic>>` - Complete data export

**Data Structure**:
```dart
{
  'parking_spots': [...],      // All parking spots
  'media_assets': [...],       // All media records
  'settings': {...},           // App settings
  'exported_at': '2024-01-01T12:00:00.000Z'
}
```

**Example**:
```dart
final export = await StorageService.exportData();
final json = jsonEncode(export);
// Save to file or share
```

---

##### `deleteAllData()`
```dart
static Future<void> deleteAllData()
```
Completely wipes all app data including database, media files, and settings.

**Warning**: This operation is irreversible.

**Example**:
```dart
// Confirm with user first
await StorageService.deleteAllData();
```

---

### NotificationService

Manages reminder notifications using native Android alarms and Flutter notifications.

**File**: `lib/services/notification_service.dart`

#### Initialization

##### `initialize()`
```dart
static Future<void> initialize()
```
Initializes the notification system and creates notification channels.

**Must be called before using other notification methods.**

**Example**:
```dart
await NotificationService.initialize();
```

---

#### Scheduling

##### `scheduleReminder()`
```dart
static Future<void> scheduleReminder({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledTime,
})
```
Schedules a reminder notification using native Android AlarmManager.

**Parameters**:
- `id` (int): Unique notification identifier
- `title` (String): Notification title
- `body` (String): Notification message
- `scheduledTime` (DateTime): When to show notification

**Throws**:
- `PlatformException` - If exact alarm permission denied
- `ArgumentError` - If scheduled time is in the past

**Example**:
```dart
await NotificationService.scheduleReminder(
  id: 123,
  title: 'Parking Reminder',
  body: 'Your parking time expires in 15 minutes',
  scheduledTime: DateTime.now().add(Duration(hours: 2)),
);
```

---

##### `showImmediate()`
```dart
static Future<void> showImmediate({
  required int id,
  required String title,
  required String body,
})
```
Shows an immediate notification.

**Parameters**:
- `id` (int): Unique notification identifier
- `title` (String): Notification title
- `body` (String): Notification message

**Example**:
```dart
await NotificationService.showImmediate(
  id: 999,
  title: 'Spot Saved',
  body: 'Your parking location has been saved successfully',
);
```

---

#### Management

##### `cancel()`
```dart
static Future<void> cancel(int id)
```
Cancels a specific notification by ID.

**Parameters**:
- `id` (int): Notification identifier to cancel

**Example**:
```dart
await NotificationService.cancel(123);
```

---

##### `cancelAll()`
```dart
static Future<void> cancelAll()
```
Cancels all pending notifications and alarms.

**Example**:
```dart
await NotificationService.cancelAll();
```

---

#### Query

##### `getPendingNotifications()`
```dart
static Future<List<dynamic>> getPendingNotifications()
```
Gets list of pending Flutter notifications (does not include native alarms).

**Returns**: `Future<List<dynamic>>` - List of pending notification details

**Example**:
```dart
final pending = await NotificationService.getPendingNotifications();
print('Pending notifications: ${pending.length}');
```

---

#### Testing

##### `testNativeAlarm()`
```dart
static Future<void> testNativeAlarm()
```
Tests native Android AlarmManager functionality with detailed logging.

**For debugging/development only.**

**Example**:
```dart
await NotificationService.testNativeAlarm();
// Check debug logs for test results
```

---

### NativeAlarmService

Native Android AlarmManager integration for reliable reminder notifications.

**File**: `lib/services/native_alarm_service.dart`

#### Scheduling

##### `scheduleNativeAlarm()`
```dart
static Future<bool> scheduleNativeAlarm({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledTime,
})
```
Schedules a native Android alarm using AlarmManager.

**Parameters**:
- `id` (int): Unique alarm identifier
- `title` (String): Notification title
- `body` (String): Notification message  
- `scheduledTime` (DateTime): When to trigger alarm

**Returns**: `Future<bool>` - `true` if scheduled successfully

**Example**:
```dart
final success = await NativeAlarmService.scheduleNativeAlarm(
  id: 456,
  title: 'Parking Reminder',
  body: 'Time to move your car!',
  scheduledTime: DateTime.now().add(Duration(hours: 1)),
);
print('Alarm scheduled: $success');
```

---

##### `cancelNativeAlarm()`
```dart
static Future<void> cancelNativeAlarm(int id)
```
Cancels a specific native alarm by ID.

**Parameters**:
- `id` (int): Alarm identifier to cancel

**Example**:
```dart
await NativeAlarmService.cancelNativeAlarm(456);
```

---

#### Permissions

##### `canScheduleExactAlarms()`
```dart
static Future<bool> canScheduleExactAlarms()
```
Checks if the app has permission to schedule exact alarms (required on Android 12+).

**Returns**: `Future<bool>` - `true` if exact alarms are allowed

**Example**:
```dart
final canSchedule = await NativeAlarmService.canScheduleExactAlarms();
if (!canSchedule) {
  // Request exact alarm permission
}
```

---

## Data Models

### ParkingSpot

Core data model representing a saved parking location.

**File**: `lib/models/parking_spot.dart`

#### Constructor

```dart
ParkingSpot({
  required this.id,
  required this.createdAt,
  required this.latitude,
  required this.longitude,
  required this.accuracyMeters,
  this.address,
  this.note,
  this.levelOrSpot,
  this.mediaIds = const [],
  this.reminderAt,
  this.source = SaveSource.manual,
  this.isActive = false,
})
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | String | Unique identifier (UUID) |
| `createdAt` | DateTime | When spot was saved |
| `latitude` | double | GPS latitude coordinate |
| `longitude` | double | GPS longitude coordinate |
| `accuracyMeters` | double | GPS accuracy in meters |
| `address` | String? | Human-readable address |
| `note` | String? | User notes |
| `levelOrSpot` | String? | Floor/section info |
| `mediaIds` | List<String> | Associated photo IDs |
| `reminderAt` | DateTime? | Reminder time |
| `source` | SaveSource | How spot was saved |
| `isActive` | bool | Currently active spot |

#### Computed Properties

##### `accuracy`
```dart
ParkingLocationAccuracy get accuracy
```
GPS accuracy classification (High/Medium/Low).

##### `accuracyLabel`
```dart
String get accuracyLabel
```
Human-readable accuracy level ("High", "Medium", "Low").

##### `accuracyHint`
```dart
String get accuracyHint
```
Helpful description of accuracy level and suggestions.

##### `timeSinceSaved`
```dart
Duration get timeSinceSaved
```
Time elapsed since spot was saved.

##### `timeAgoLabel`
```dart
String get timeAgoLabel
```
Human-readable time ago string ("5m ago", "2h 30m ago", "3d ago").

#### Methods

##### `toMap()`
```dart
Map<String, dynamic> toMap()
```
Converts to Map for database storage.

##### `fromMap()`
```dart
factory ParkingSpot.fromMap(Map<String, dynamic> map)
```
Creates instance from database Map.

##### `copyWith()`
```dart
ParkingSpot copyWith({...})
```
Creates copy with modified properties.

---

### MediaAsset

Represents a photo or other media file associated with a parking spot.

**File**: `lib/models/parking_spot.dart`

#### Constructor

```dart
MediaAsset({
  required this.id,
  required this.spotId,
  required this.type,
  required this.localPath,
  required this.createdAt,
})
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | String | Unique media identifier |
| `spotId` | String | Associated parking spot ID |
| `type` | String | Media type ("photo") |
| `localPath` | String | File system path |
| `createdAt` | DateTime | When media was created |

#### Computed Properties

##### `file`
```dart
File get file
```
Returns File object for the media asset.

##### `exists`
```dart
bool get exists
```
Checks if the media file exists on disk.

---

### AppSettings

User preferences and app configuration.

**File**: `lib/models/parking_spot.dart`

#### Constructor

```dart
AppSettings({
  this.distanceUnit = 'km',
  this.defaultDurationMinutes,
  this.askDurationOnSave = false,
  this.defaultNavigationApp,
  this.privacyLocalOnly = true,
  this.language = 'en',
  this.showAccuracyHints = true,
})
```

#### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `distanceUnit` | String | 'km' | Distance unit ('km' or 'miles') |
| `defaultDurationMinutes` | int? | null | Default parking duration |
| `askDurationOnSave` | bool | false | Prompt for duration when saving |
| `defaultNavigationApp` | String? | null | Preferred navigation app |
| `privacyLocalOnly` | bool | true | Local storage only (always true) |
| `language` | String | 'en' | App language |
| `showAccuracyHints` | bool | true | Show GPS accuracy guidance |

---

## Utilities

### Logger

Simple debugging and logging utility.

**File**: `lib/utils/logger.dart`

#### Methods

##### `d()`
```dart
static void d(String message)
```
Logs debug message (only in debug builds).

**Parameters**:
- `message` (String): Debug message to log

**Example**:
```dart
Logger.d('LocationService: GPS accuracy = ${position.accuracy}m');
```

---

##### `e()`
```dart
static void e(String message, [Object? error])
```
Logs error message with optional error object.

**Parameters**:
- `message` (String): Error description
- `error` (Object?): Optional error object or stack trace

**Example**:
```dart
try {
  await riskyOperation();
} catch (e) {
  Logger.e('Operation failed', e);
}
```

---

## Enums & Constants

### ParkingLocationAccuracy

GPS accuracy classification levels.

```dart
enum ParkingLocationAccuracy {
  high,    // ≤25 meters - Excellent GPS signal
  medium,  // 26-75 meters - Good GPS signal  
  low,     // >75 meters - Weak GPS signal
}
```

### SaveSource

How a parking spot was created.

```dart
enum SaveSource {
  manual,              // User manually saved
  btDisconnect,        // Bluetooth disconnect trigger
  carplayDisconnect,   // CarPlay disconnect trigger
  ssidDisconnect,      // WiFi disconnect trigger
}
```

### Constants

#### Storage Limits
```dart
class StorageService {
  static const int maxHistorySpots = 50;
}
```

#### Timeouts
```dart
class LocationService {
  static const Duration locationTimeout = Duration(seconds: 6);
}
```

---

## Error Handling

### Common Exceptions

#### LocationServiceDisabledException
Thrown when GPS services are disabled on the device.

```dart
try {
  final position = await LocationService.getCurrentLocation();
} on LocationServiceDisabledException {
  // Prompt user to enable GPS
}
```

#### PermissionDeniedException
Thrown when location permission is denied.

```dart
try {
  final position = await LocationService.getCurrentLocation();
} on PermissionDeniedException {
  // Handle permission denied
}
```

#### TimeoutException
Thrown when GPS acquisition times out.

```dart
try {
  final position = await LocationService.getCurrentLocation();
} on TimeoutException {
  // Handle GPS timeout
}
```

#### PlatformException
Thrown for platform-specific errors (e.g., notification permissions).

```dart
try {
  await NotificationService.scheduleReminder(...);
} on PlatformException catch (e) {
  Logger.e('Platform error: ${e.message}');
}
```

---

## Threading & Async

### Best Practices

#### Service Methods
All service methods are async and should be awaited:

```dart
// ✅ Correct
final spot = await StorageService.getActiveSpot();

// ❌ Incorrect
final spot = StorageService.getActiveSpot(); // Returns Future<ParkingSpot?>
```

#### Error Handling
Always wrap service calls in try-catch:

```dart
try {
  await StorageService.saveParkingSpot(spot);
} catch (e) {
  Logger.e('Failed to save spot', e);
  // Handle error appropriately
}
```

#### UI Updates
Update UI state after async operations:

```dart
Future<void> _loadData() async {
  setState(() => _isLoading = true);
  try {
    final spot = await StorageService.getActiveSpot();
    setState(() => _currentSpot = spot);
  } finally {
    setState(() => _isLoading = false);
  }
}
```

---

## Performance Considerations

### Database Queries

#### Efficient Active Spot Lookup
```dart
// Uses index on is_active column
final activeSpot = await db.query(
  'parking_spots',
  where: 'is_active = 1',
  limit: 1,
);
```

#### Paginated History
```dart
// Uses index on created_at column
final history = await db.query(
  'parking_spots',
  where: 'is_active = 0',
  orderBy: 'created_at DESC',
  limit: 20,
  offset: page * 20,
);
```

### Memory Management

#### Image Compression
Photos are automatically compressed to 1200px width to reduce memory usage.

#### Database Cleanup
Historical spots are automatically limited to 50 entries with cleanup on each save.

---

This API reference provides comprehensive documentation for all public interfaces in the Anchor parking app. For implementation examples and architecture details, see `docs/ARCHITECTURE.md` and `docs/DEVELOPMENT.md`.
