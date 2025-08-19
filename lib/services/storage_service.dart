import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:anchor/models/parking_spot.dart';

class StorageService {
  static Database? _database;
  static SharedPreferences? _prefs;
  
  static const int maxHistorySpots = 50;

  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<Database> _initDatabase() async {
    final documentsDirectory = await getDatabasesPath();
    final path = join(documentsDirectory, 'parking_spots.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  static Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE parking_spots (
        id TEXT PRIMARY KEY,
        created_at INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy_meters REAL NOT NULL,
        address TEXT,
        note TEXT,
        level_or_spot TEXT,
        media_ids TEXT,
        reminder_at INTEGER,
        source INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE media_assets (
        id TEXT PRIMARY KEY,
        spot_id TEXT NOT NULL,
        type TEXT NOT NULL,
        local_path TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (spot_id) REFERENCES parking_spots (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_active_spots ON parking_spots (is_active)');
    await db.execute('CREATE INDEX idx_created_at ON parking_spots (created_at DESC)');
  }

  // Parking Spot operations
  static Future<void> saveParkingSpot(ParkingSpot spot) async {
    final db = await database;
    
    // First, deactivate any existing active spots
    if (spot.isActive) {
      await db.update(
        'parking_spots',
        {'is_active': 0},
        where: 'is_active = 1',
      );
    }

    await db.insert(
      'parking_spots',
      spot.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Clean up old spots if we exceed the maximum
    await _cleanupOldSpots();
  }

  static Future<ParkingSpot?> getActiveSpot() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'parking_spots',
      where: 'is_active = 1',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return ParkingSpot.fromMap(maps.first);
    }
    return null;
  }

  static Future<void> updateSpotAddress(String spotId, String address) async {
    final db = await database;
    await db.update(
      'parking_spots',
      {'address': address},
      where: 'id = ?',
      whereArgs: [spotId],
    );
  }

  static Future<void> deleteSpot(String spotId) async {
    final db = await database;
    
    // Delete associated media files
    final mediaAssets = await getMediaForSpot(spotId);
    for (final asset in mediaAssets) {
      try {
        await asset.file.delete();
      } catch (e) {
        // Ignore file deletion errors
      }
    }

    await db.delete(
      'parking_spots',
      where: 'id = ?',
      whereArgs: [spotId],
    );
  }

  static Future<void> deactivateCurrentSpot() async {
    final db = await database;
    await db.update(
      'parking_spots',
      {'is_active': 0},
      where: 'is_active = 1',
    );
  }

  static Future<List<ParkingSpot>> getHistorySpots({
    int limit = 20,
    String? searchQuery,
  }) async {
    final db = await database;
    String whereClause = 'is_active = 0';
    List<String> whereArgs = [];

    if (searchQuery?.isNotEmpty == true) {
      whereClause += ' AND (note LIKE ? OR address LIKE ? OR level_or_spot LIKE ?)';
      final query = '%$searchQuery%';
      whereArgs.addAll([query, query, query]);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'parking_spots',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return maps.map((map) => ParkingSpot.fromMap(map)).toList();
  }

  static Future<void> _cleanupOldSpots() async {
    final db = await database;
    
    // Keep only the most recent spots beyond the limit
    final List<Map<String, dynamic>> oldSpots = await db.query(
      'parking_spots',
      where: 'is_active = 0',
      orderBy: 'created_at DESC',
      limit: -1,
      offset: maxHistorySpots,
    );

    for (final spotData in oldSpots) {
      await deleteSpot(spotData['id']);
    }
  }

  // Media Asset operations
  static Future<void> saveMediaAsset(MediaAsset asset) async {
    final db = await database;
    await db.insert(
      'media_assets',
      asset.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<MediaAsset>> getMediaForSpot(String spotId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'media_assets',
      where: 'spot_id = ?',
      whereArgs: [spotId],
      orderBy: 'created_at ASC',
    );

    return maps.map((map) => MediaAsset.fromMap(map)).toList();
  }

  static Future<String> getMediaDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(join(directory.path, 'media'));
    
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    
    return mediaDir.path;
  }

  // Settings operations
  static Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final settingsMap = settings.toMap();
    
    for (final entry in settingsMap.entries) {
      if (entry.value is String) {
        await prefs.setString(entry.key, entry.value);
      } else if (entry.value is int) {
        await prefs.setInt(entry.key, entry.value);
      } else if (entry.value is bool) {
        await prefs.setBool(entry.key, entry.value);
      }
    }
  }

  static Future<AppSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final settingsMap = <String, dynamic>{};
    for (final key in prefs.getKeys()) {
      settingsMap[key] = prefs.get(key);
    }

    return AppSettings.fromMap(settingsMap);
  }

  // Data export/import
  static Future<Map<String, dynamic>> exportData() async {
    final db = await database;
    
    final spots = await db.query('parking_spots', orderBy: 'created_at DESC');
    final media = await db.query('media_assets', orderBy: 'created_at ASC');
    final settings = await getSettings();

    return {
      'parking_spots': spots,
      'media_assets': media,
      'settings': settings.toMap(),
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  static Future<void> deleteAllData() async {
    final db = await database;
    
    // Delete all media files
    final mediaAssets = await db.query('media_assets');
    for (final assetMap in mediaAssets) {
      final asset = MediaAsset.fromMap(assetMap);
      try {
        await asset.file.delete();
      } catch (e) {
        // Ignore file deletion errors
      }
    }

    // Clear database tables
    await db.delete('parking_spots');
    await db.delete('media_assets');
    
    // Clear preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}