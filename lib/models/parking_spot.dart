import 'dart:io';

enum ParkingLocationAccuracy { high, medium, low }

enum SaveSource { manual, btDisconnect, carplayDisconnect, ssidDisconnect }

class ParkingSpot {
  final String id;
  final DateTime createdAt;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final String? address;
  final String? note;
  final String? levelOrSpot;
  final List<String> mediaIds;
  final DateTime? reminderAt;
  final SaveSource source;
  final bool isActive;

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
  });

  ParkingLocationAccuracy get accuracy {
    if (accuracyMeters <= 25) return ParkingLocationAccuracy.high;
    if (accuracyMeters <= 75) return ParkingLocationAccuracy.medium;
    return ParkingLocationAccuracy.low;
  }

  String get accuracyLabel {
    switch (accuracy) {
      case ParkingLocationAccuracy.high:
        return 'High';
      case ParkingLocationAccuracy.medium:
        return 'Medium';
      case ParkingLocationAccuracy.low:
        return 'Low';
    }
  }

  String get accuracyHint {
    switch (accuracy) {
      case ParkingLocationAccuracy.high:
        return 'Great GPS signal';
      case ParkingLocationAccuracy.medium:
        return 'Good GPS signal';
      case ParkingLocationAccuracy.low:
        return 'GPS weak (indoors?). Add a photo or floor/section.';
    }
  }

  Duration get timeSinceSaved => DateTime.now().difference(createdAt);

  String get timeAgoLabel {
    final duration = timeSinceSaved;
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ago';
    } else if (duration.inHours < 24) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m ago';
    } else {
      return '${duration.inDays}d ago';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt.millisecondsSinceEpoch,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy_meters': accuracyMeters,
      'address': address,
      'note': note,
      'level_or_spot': levelOrSpot,
      'media_ids': mediaIds.join(','),
      'reminder_at': reminderAt?.millisecondsSinceEpoch,
      'source': source.index,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory ParkingSpot.fromMap(Map<String, dynamic> map) {
    return ParkingSpot(
      id: map['id'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      latitude: map['latitude'],
      longitude: map['longitude'],
      accuracyMeters: map['accuracy_meters'],
      address: map['address'],
      note: map['note'],
      levelOrSpot: map['level_or_spot'],
      mediaIds: map['media_ids'] is String && (map['media_ids'] as String).isNotEmpty
          ? (map['media_ids'] as String).split(',').whereType<String>().where((id) => id.isNotEmpty).toList()
          : [],
      reminderAt: map['reminder_at'] != null ? DateTime.fromMillisecondsSinceEpoch(map['reminder_at']) : null,
      source: SaveSource.values[map['source'] ?? 0],
      isActive: map['is_active'] == 1,
    );
  }

  ParkingSpot copyWith({
    String? id,
    DateTime? createdAt,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    String? address,
    String? note,
    String? levelOrSpot,
    List<String>? mediaIds,
    DateTime? reminderAt,
    SaveSource? source,
    bool? isActive,
  }) {
    return ParkingSpot(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      address: address ?? this.address,
      note: note ?? this.note,
      levelOrSpot: levelOrSpot ?? this.levelOrSpot,
      mediaIds: mediaIds ?? this.mediaIds,
      reminderAt: reminderAt ?? this.reminderAt,
      source: source ?? this.source,
      isActive: isActive ?? this.isActive,
    );
  }
}

class MediaAsset {
  final String id;
  final String spotId;
  final String type;
  final String localPath;
  final DateTime createdAt;

  MediaAsset({
    required this.id,
    required this.spotId,
    required this.type,
    required this.localPath,
    required this.createdAt,
  });

  File get file => File(localPath);
  bool get exists => file.existsSync();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'spot_id': spotId,
      'type': type,
      'local_path': localPath,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory MediaAsset.fromMap(Map<String, dynamic> map) {
    return MediaAsset(
      id: map['id'],
      spotId: map['spot_id'],
      type: map['type'],
      localPath: map['local_path'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }
}

class AppSettings {
  final String distanceUnit;
  final int? defaultDurationMinutes;
  final bool askDurationOnSave;
  final String? defaultNavigationApp;
  final bool privacyLocalOnly;
  final String language;
  final bool showAccuracyHints;

  AppSettings({
    this.distanceUnit = 'km',
    this.defaultDurationMinutes,
    this.askDurationOnSave = false,
    this.defaultNavigationApp,
    this.privacyLocalOnly = true,
    this.language = 'en',
    this.showAccuracyHints = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'distance_unit': distanceUnit,
      'default_duration_minutes': defaultDurationMinutes,
      'ask_duration_on_save': askDurationOnSave ? 1 : 0,
      'default_navigation_app': defaultNavigationApp,
      'privacy_local_only': privacyLocalOnly ? 1 : 0,
      'language': language,
      'show_accuracy_hints': showAccuracyHints ? 1 : 0,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      distanceUnit: map['distance_unit'] ?? 'km',
      defaultDurationMinutes: map['default_duration_minutes'],
      askDurationOnSave: map['ask_duration_on_save'] == 1,
      defaultNavigationApp: map['default_navigation_app'],
      privacyLocalOnly: map['privacy_local_only'] == 1,
      language: map['language'] ?? 'en',
      showAccuracyHints: map['show_accuracy_hints'] == 1,
    );
  }

  AppSettings copyWith({
    String? distanceUnit,
    int? defaultDurationMinutes,
    bool? askDurationOnSave,
    String? defaultNavigationApp,
    bool? privacyLocalOnly,
    String? language,
    bool? showAccuracyHints,
  }) {
    return AppSettings(
      distanceUnit: distanceUnit ?? this.distanceUnit,
      defaultDurationMinutes: defaultDurationMinutes ?? this.defaultDurationMinutes,
      askDurationOnSave: askDurationOnSave ?? this.askDurationOnSave,
      defaultNavigationApp: defaultNavigationApp ?? this.defaultNavigationApp,
      privacyLocalOnly: privacyLocalOnly ?? this.privacyLocalOnly,
      language: language ?? this.language,
      showAccuracyHints: showAccuracyHints ?? this.showAccuracyHints,
    );
  }
}