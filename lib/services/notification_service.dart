import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:anchor/utils/logger.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      tzdata.initializeTimeZones();
      
      // Try to get device timezone, fallback to a common one for your region
      try {
        // For Android, try to detect timezone automatically
        final String timeZoneName = DateTime.now().timeZoneName;
        if (timeZoneName.isNotEmpty) {
          // Common timezone mappings for Southeast Asia
          String tzIdentifier = timeZoneName;
          if (timeZoneName.contains('ICT') || timeZoneName.contains('+07')) {
            tzIdentifier = 'Asia/Bangkok'; // UTC+7
          } else if (timeZoneName.contains('WIB')) {
            tzIdentifier = 'Asia/Jakarta'; // UTC+7
          } else if (timeZoneName.contains('WITA')) {
            tzIdentifier = 'Asia/Makassar'; // UTC+8
          }
          
          final location = tz.getLocation(tzIdentifier);
          tz.setLocalLocation(location);
          Logger.d('NotificationService: timezone set to $tzIdentifier (detected: $timeZoneName)');
        } else {
          // Fallback to UTC+7 (common for Vietnam/Thailand/Indonesia)
          tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
          Logger.d('NotificationService: timezone set to Asia/Ho_Chi_Minh (fallback)');
        }
      } catch (e) {
        // If timezone detection fails, use UTC+7 as fallback
        tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
        Logger.d('NotificationService: timezone detection failed, using Asia/Ho_Chi_Minh: $e');
      }
      
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: androidSettings);
      
      await _notifications.initialize(settings);
      
      // Create notification channels
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        const reminderChannel = AndroidNotificationChannel(
          'reminder_channel',
          'Parking Reminders',
          description: 'Reminders for parking duration',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          showBadge: true,
        );
        
        const navigationChannel = AndroidNotificationChannel(
          'navigation_channel',
          'Navigation',
          description: 'Navigation actions',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          showBadge: true,
        );
        
        await androidPlugin.createNotificationChannel(reminderChannel);
        await androidPlugin.createNotificationChannel(navigationChannel);
      }
      
      _isInitialized = true;
      Logger.d('NotificationService: initialized successfully');
    } catch (e) {
      Logger.d('NotificationService: initialization failed: $e');
    }
  }

  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (!_isInitialized) await initialize();
    
    try {
      // Cancel any existing notification with this ID
      await _notifications.cancel(id);
      
      final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);
      
      // Try exact scheduling first, fallback to inexact if permission denied
      try {
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          tzDateTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'reminder_channel',
              'Parking Reminders',
              channelDescription: 'Reminders for parking duration',
              importance: Importance.max,
              priority: Priority.high,
              enableVibration: true,
              playSound: true,
              enableLights: true,
              fullScreenIntent: true,
              category: AndroidNotificationCategory.alarm,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        
        Logger.d('NotificationService: scheduled exact reminder for ${tzDateTime.toString()}');
      } catch (exactError) {
        Logger.d('NotificationService: exact scheduling failed, trying inexact: $exactError');
        
        // Fallback to inexact scheduling
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          tzDateTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'reminder_channel',
              'Parking Reminders',
              channelDescription: 'Reminders for parking duration',
              importance: Importance.max,
              priority: Priority.high,
              enableVibration: true,
              playSound: true,
              enableLights: true,
              fullScreenIntent: true,
              category: AndroidNotificationCategory.alarm,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.alarmClock,
        );
        
        Logger.d('NotificationService: scheduled inexact reminder for ${tzDateTime.toString()}');
      }
    } catch (e) {
      Logger.d('NotificationService: failed to schedule reminder: $e');
      rethrow;
    }
  }

  static Future<void> showImmediate({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await initialize();
    
    try {
      await _notifications.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Parking Reminders',
            channelDescription: 'Reminders for parking duration',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
      
      Logger.d('NotificationService: showed immediate notification');
    } catch (e) {
      Logger.d('NotificationService: failed to show immediate notification: $e');
      rethrow;
    }
  }

  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) await initialize();
    
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      Logger.d('NotificationService: failed to get pending notifications: $e');
      return [];
    }
  }

  static Future<void> cancelAll() async {
    if (!_isInitialized) await initialize();
    
    try {
      await _notifications.cancelAll();
      Logger.d('NotificationService: cancelled all notifications');
    } catch (e) {
      Logger.d('NotificationService: failed to cancel notifications: $e');
    }
  }

  static Future<void> cancel(int id) async {
    if (!_isInitialized) await initialize();
    
    try {
      await _notifications.cancel(id);
      Logger.d('NotificationService: cancelled notification $id');
    } catch (e) {
      Logger.d('NotificationService: failed to cancel notification $id: $e');
    }
  }

  // Debug helper to check notification system status
  static Future<void> debugNotificationStatus() async {
    try {
      if (!_isInitialized) await initialize();
      
      Logger.d('=== NOTIFICATION DEBUG INFO ===');
      Logger.d('NotificationService initialized: $_isInitialized');
      Logger.d('Current timezone: ${tz.local}');
      Logger.d('Current time: ${DateTime.now()}');
      Logger.d('Current TZ time: ${tz.TZDateTime.now(tz.local)}');
      
      final pending = await getPendingNotifications();
      Logger.d('Pending notifications: ${pending.length}');
      for (final notif in pending) {
        Logger.d('  - ID: ${notif.id}, Title: ${notif.title}, Body: ${notif.body}');
      }
      
      // Check Android plugin availability
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      Logger.d('Android plugin available: ${androidPlugin != null}');
      
      // Test immediate notification
      Logger.d('Testing immediate notification...');
      await showImmediate(
        id: 99999,
        title: 'Debug Test',
        body: 'If you see this, immediate notifications work!',
      );
      
      Logger.d('=== END DEBUG INFO ===');
    } catch (e) {
      Logger.d('NotificationService debug failed: $e');
    }
  }
}
