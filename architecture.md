# One-Tap Parking Saver - Architecture Plan

## 1. Core App Structure (3 Screens Maximum)
- **Home Screen**: Primary parking actions with smart state management
- **History Screen**: Past parking spots with search/filter
- **Settings Screen**: Privacy controls, reminders, and preferences

## 2. Key Components & Widgets
- **PrimaryActionButton**: Large FAB-style button that changes based on app state
- **CurrentSpotCard**: Displays active parking spot with actions
- **AccuracyIndicator**: Visual GPS accuracy feedback
- **SaveSpotSheet**: Bottom sheet for saving with photo/note options
- **NavigationSheet**: Choose navigation method
- **SpotHistoryItem**: Card-based history list items

## 3. Data Models
- **ParkingSpot**: Core parking data with location, time, media, accuracy
- **AppSettings**: User preferences, reminders, privacy settings
- **LocationAccuracy**: GPS accuracy levels (High/Medium/Low)

## 4. Services & Logic
- **LocationService**: GPS handling, accuracy assessment, geocoding
- **StorageService**: Local data persistence using SharedPreferences/SQLite
- **NavigationService**: Launch external navigation apps
- **NotificationService**: Local reminders and alerts

## 5. State Management
- **ParkingState**: Tracks active spot, app state (no spot/has spot)
- **SettingsState**: User preferences and configuration
- **HistoryState**: Recent parking spots list

## 6. Key Features Implementation
- Single active spot logic (auto-archive previous)
- Smart GPS accuracy feedback with visual indicators
- Photo capture and local storage
- External navigation app integration
- Local notifications for reminders
- Privacy-first local data storage

## 7. File Structure (10 files total)
1. `lib/main.dart` - App entry point
2. `lib/models/parking_spot.dart` - Data models
3. `lib/services/location_service.dart` - GPS and location handling
4. `lib/services/storage_service.dart` - Local data persistence
5. `lib/screens/home_screen.dart` - Primary parking interface
6. `lib/screens/history_screen.dart` - Past spots listing
7. `lib/screens/settings_screen.dart` - App configuration
8. `lib/widgets/primary_action_button.dart` - Main interaction button
9. `lib/widgets/current_spot_card.dart` - Active spot display
10. `lib/widgets/save_spot_sheet.dart` - Bottom sheet for saving

## 8. Dependencies Required
- `geolocator` - GPS location services
- `geocoding` - Reverse geocoding for addresses
- `image_picker` - Camera for photos
- `shared_preferences` - Settings storage
- `sqflite` - Local database for spots
- `url_launcher` - External navigation apps
- `flutter_local_notifications` - Reminder alerts

## 9. Platform Permissions
- Location (always/when in use)
- Camera (for photos)
- External storage (for photo storage)

## 10. Success Criteria
- One-tap save and navigate functionality
- Works offline with graceful GPS degradation
- Clear visual feedback for location accuracy
- Privacy-first local data storage
- Reliable reminder notifications