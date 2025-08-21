# 🔒 Privacy Policy & Security

## Overview

Anchor is designed with **privacy-first** principles. This document outlines our commitment to protecting your data and details exactly how information is handled within the app.

## Core Privacy Principles

### 🏠 Local-Only Data Storage
- **100% Local**: All data remains on your device, always
- **No Cloud Sync**: No data is transmitted to external servers
- **No Account Required**: No sign-up, login, or user tracking
- **Offline Capable**: App works completely without internet connection

### 🚫 What We DON'T Collect
- ❌ **No Personal Information**: Name, email, phone number, etc.
- ❌ **No Device Identifiers**: IMEI, advertising ID, device fingerprinting
- ❌ **No Usage Analytics**: No tracking of how you use the app
- ❌ **No Location Tracking**: No continuous or background location monitoring
- ❌ **No Network Communications**: App never sends data over the internet
- ❌ **No Third-Party Services**: No analytics, crash reporting, or ad networks

## Data We Store (Locally Only)

### Parking Location Data
| Data Type | Purpose | Storage Location | Retention |
|-----------|---------|------------------|-----------|
| GPS Coordinates | Finding your car | Local SQLite database | Until you delete |
| GPS Accuracy | Location reliability info | Local SQLite database | Until you delete |
| Save Timestamp | When you parked | Local SQLite database | Until you delete |
| Address Lookup | Human-readable location | Local SQLite database | Until you delete |

### Optional User Data
| Data Type | Purpose | Storage Location | Retention |
|-----------|---------|------------------|-----------|
| Photos | Visual identification | App documents folder | Until you delete |
| Notes | Additional context | Local SQLite database | Until you delete |
| Floor/Section | Parking details | Local SQLite database | Until you delete |
| Reminders | Notification timing | Local SQLite database | Until you delete |

### App Settings
| Data Type | Purpose | Storage Location | Retention |
|-----------|---------|------------------|-----------|
| Distance Unit | Display preferences | SharedPreferences | Until app uninstall |
| Navigation App | Default app choice | SharedPreferences | Until app uninstall |
| Accuracy Hints | UI preferences | SharedPreferences | Until app uninstall |

## Technical Security Measures

### Data Encryption
- **At Rest**: Files stored in Android's secure app sandbox
- **Database**: SQLite database in app-private directory
- **Photos**: Stored in app documents folder (not accessible to other apps)
- **Settings**: Android SharedPreferences with app-private access

### Access Controls
```
App Data Isolation:
┌─────────────────────────────────────┐
│ Android App Sandbox                │
│ (/data/data/com.dash_laifu.anchor/) │
│                                     │
│ ├── databases/                     │ 
│ │   └── parking_spots.db           │ ← Only Anchor can access
│ ├── files/media/                   │
│ │   └── photos/                    │ ← Only Anchor can access
│ └── shared_prefs/                  │
│     └── settings.xml               │ ← Only Anchor can access
└─────────────────────────────────────┘
```

### Permission Minimization
We only request permissions essential for core functionality:

#### Required Permissions
- **Location (Fine/Coarse)**: To save your parking spot coordinates
  - Used only when you tap "Save Spot"
  - No background location tracking
  - No continuous monitoring

#### Optional Permissions
- **Camera**: To take photos for spot identification
  - Only when you choose to add a photo
  - Photos stored locally only
- **Exact Alarms**: For reliable parking reminders
  - Only if you set a reminder
  - Uses Android's native alarm system

#### Not Requested
- ❌ Internet/Network access
- ❌ Phone/SMS access
- ❌ Contacts access
- ❌ Storage access (beyond app folder)
- ❌ Microphone access
- ❌ Calendar access

## Data Retention & Deletion

### Automatic Cleanup
- **History Limit**: Maximum 50 parking spots stored
- **Auto-Cleanup**: Oldest spots automatically removed when limit exceeded
- **Media Cleanup**: Photos deleted when associated spots are removed

### Manual Data Control
Users have complete control over their data:

#### Individual Spot Deletion
```dart
// Delete specific parking spot and associated photos
await StorageService.deleteSpot(spotId);
```

#### Complete Data Wipe
```dart
// Delete ALL app data (irreversible)
await StorageService.deleteAllData();
```

#### Data Export (Backup)
```dart
// Export all data for personal backup
final backup = await StorageService.exportData();
```

### App Uninstall
When you uninstall Anchor:
- ✅ All app data automatically deleted by Android
- ✅ All photos permanently removed
- ✅ All settings cleared
- ✅ No trace left on device

## Location Privacy

### GPS Usage Policy
- **One-Time Acquisition**: GPS only activated when saving a spot
- **User-Initiated**: Location only captured when you tap "Save Spot"
- **6-Second Timeout**: Prevents hanging/excessive battery drain
- **No Background Tracking**: App never monitors location in background
- **No Location History**: Only current/active spot location stored

### Location Accuracy
- **Intentional Limitation**: We classify accuracy levels but don't expose precise coordinates in UI
- **User Awareness**: Clear visual feedback on GPS accuracy quality
- **Graceful Degradation**: App works even with poor GPS signal

### Address Lookup
- **On-Device Only**: Uses Android's native geocoding service
- **No External APIs**: No calls to Google/other mapping services
- **Optional**: Address lookup only if GPS coordinates available
- **Local Cache**: Addresses stored locally for faster access

## Notification Privacy

### Reminder System
- **Local Notifications**: Uses Android's native notification system
- **No External Services**: No push notification providers
- **User Control**: Reminders only when explicitly set by user
- **Native Alarms**: Uses Android AlarmManager for reliability

### Notification Content
- **Generic Messages**: Notifications don't reveal specific location details
- **User-Controlled**: You choose if/when to set reminders
- **Local Processing**: All notification logic runs on device

## Third-Party Dependencies

We carefully vet all dependencies to ensure privacy compliance:

### Core Dependencies
| Package | Purpose | Privacy Notes |
|---------|---------|---------------|
| `geolocator` | GPS access | Local device API only |
| `geocoding` | Address lookup | Uses Android system service |
| `sqflite` | Local database | 100% local storage |
| `shared_preferences` | Settings storage | Local Android preferences |
| `image_picker` | Camera access | Local device camera only |
| `flutter_local_notifications` | Reminders | Local notification system |
| `path_provider` | File paths | Local file system access |

### No Analytics/Tracking
- ❌ No Google Analytics
- ❌ No Firebase
- ❌ No Crashlytics  
- ❌ No advertisement SDKs
- ❌ No user behavior tracking

## Compliance & Standards

### Privacy Regulations
- **GDPR Compliant**: No personal data collection or processing
- **CCPA Compliant**: No sale or sharing of personal information
- **COPPA Compliant**: No data collection from children
- **Local Laws**: Complies with privacy laws by design (no data collection)

### Security Standards
- **OWASP Mobile**: Follows mobile security best practices
- **Android Security**: Leverages Android's security model
- **Code Security**: No hardcoded secrets or API keys
- **Input Validation**: Proper sanitization of user inputs

## Transparency & Trust

### Open Source Approach
While not fully open source, we maintain transparency through:
- **Detailed Documentation**: Complete technical documentation
- **Clear Privacy Policy**: Explicit about data handling
- **Local-First Design**: Architecture prevents privacy violations
- **User Control**: Complete control over your data

### Audit Trail
You can verify our privacy claims:
- **Network Monitoring**: App makes no network requests
- **File System**: All data in app-private directories
- **Permissions**: Minimal permission requests
- **Source Code**: Available for security review upon request

## User Rights & Control

### Your Data Rights
As a user, you have complete control:
- ✅ **Access**: View all your stored parking spots and settings
- ✅ **Portability**: Export your data in JSON format
- ✅ **Deletion**: Delete individual spots or all data
- ✅ **Modification**: Edit or update any saved information
- ✅ **Consent**: Control which optional features to use

### How to Exercise Rights

#### View Your Data
```
Settings → Debug → Export Data
```

#### Delete Specific Data
```
History → Select Spot → Delete
```

#### Delete All Data
```
Settings → Delete All Data → Confirm
```

#### Control Permissions
```
Android Settings → Apps → Anchor → Permissions
```

## Contact & Questions

### Privacy Concerns
If you have questions about privacy or data handling:
- **Technical Questions**: Review this documentation and API reference
- **Security Issues**: Report through appropriate channels
- **General Privacy**: Contact through official channels

### Self-Service Options
Most privacy questions can be answered by:
- **Reviewing Code**: Architecture is transparent and documented
- **Testing Yourself**: Use network monitoring tools to verify no data transmission
- **Local Verification**: Check file system for data storage locations

## Updates to Privacy Policy

### Change Management
- **Version Control**: Privacy policy changes tracked in documentation
- **User Notification**: Significant changes communicated through app updates
- **Backward Compatibility**: Changes won't affect existing data handling
- **Transparency**: All changes documented with reasoning

### Current Version
- **Version**: 1.0
- **Last Updated**: 2024
- **Effective Date**: Upon app installation
- **Review Cycle**: Annually or upon significant app changes

## Privacy by Design

Anchor was built from the ground up with privacy as a core principle:

### Design Decisions
- **Local-First Architecture**: Fundamental design choice, not an afterthought
- **Minimal Data Collection**: Only essential data for core functionality
- **No Network Dependencies**: App designed to work completely offline
- **User Empowerment**: Users control all aspects of their data

### Technical Implementation
```dart
// Example: No analytics or tracking code
class AnalyticsService {
  // This class intentionally empty
  // No user tracking implemented
}

// Example: Local-only storage
class StorageService {
  static Future<Database> get database async {
    // Local SQLite only - no cloud connection
    final path = join(await getDatabasesPath(), 'parking_spots.db');
    return openDatabase(path);
  }
}
```

### Privacy Testing
We test privacy compliance through:
- **Network Traffic Analysis**: Verify no external communications
- **File System Audits**: Confirm data stays in app sandbox
- **Permission Testing**: Validate minimal permission usage
- **Code Review**: Regular security and privacy reviews

---

## Summary

**Anchor respects your privacy completely:**

✅ **All data stays on your device**  
✅ **No internet connection required**  
✅ **No personal information collected**  
✅ **No tracking or analytics**  
✅ **Complete user control over data**  
✅ **Transparent and auditable**  

Your parking spots, photos, and preferences belong to you and remain on your device. We believe privacy should be the default, not an option.

---

*This privacy policy reflects our commitment to user privacy and is backed by technical implementation that makes privacy violations impossible by design.*
