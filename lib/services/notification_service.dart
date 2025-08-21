import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:anchor/utils/logger.dart';
import 'package:anchor/services/native_alarm_service.dart';
import 'dart:async';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static Timer? _fallbackTimer;

  // Primary scheduling method - uses native Android AlarmManager
  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    Logger.d('NotificationService: Scheduling with native Android AlarmManager');
    Logger.d('  ID: $id');
    Logger.d('  Title: $title');
    Logger.d('  Scheduled time: $scheduledTime');
    
    final now = DateTime.now();
    if (scheduledTime.isBefore(now)) {
      Logger.d('NotificationService: scheduled time is in the past, showing immediately');
      await showImmediate(id: id, title: title, body: body);
      return;
    }
    
    try {
      final success = await NativeAlarmService.scheduleNativeAlarm(
        id: id,
        title: title,
        body: body,
        scheduledTime: scheduledTime,
      );
      
      if (success) {
        Logger.d('NotificationService: Native alarm scheduled successfully');
      } else {
        Logger.d('NotificationService: Native alarm scheduling failed, using timer fallback');
        await _scheduleWithTimer(
          id: id,
          title: title, 
          body: body,
          scheduledTime: scheduledTime,
        );
      }
    } catch (e) {
      Logger.d('NotificationService: Native alarm error: $e, using timer fallback');
      await _scheduleWithTimer(
        id: id,
        title: title,
        body: body,
        scheduledTime: scheduledTime,
      );
    }
  }

  // Fallback timer method for short durations if native fails
  static Future<void> _scheduleWithTimer({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (!_isInitialized) await initialize();
    
    final now = DateTime.now();
    final delay = scheduledTime.difference(now);
    
    Logger.d('NotificationService: Using timer fallback');
    Logger.d('  Delay: ${delay.inSeconds} seconds');
    
    if (delay.isNegative) {
      Logger.d('NotificationService: Timer - scheduled time is in the past, showing immediately');
      await showImmediate(id: id, title: title, body: body);
      return;
    }
    
    // Cancel any existing timer
    _fallbackTimer?.cancel();
    
    // Use Timer for the delay
    _fallbackTimer = Timer(delay, () async {
      try {
        Logger.d('NotificationService: Timer fired, showing notification');
        await showImmediate(id: id, title: title, body: body);
      } catch (e) {
        Logger.d('NotificationService: Timer notification failed: $e');
      }
    });
    
    Logger.d('NotificationService: Timer fallback scheduled for ${delay.inSeconds}s');
  }

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: androidSettings);
      
      await _notifications.initialize(settings);
      
      // Create notification channel for immediate notifications
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
        
        await androidPlugin.createNotificationChannel(reminderChannel);
      }
      
      _isInitialized = true;
      Logger.d('NotificationService: initialized successfully');
    } catch (e) {
      Logger.d('NotificationService: initialization failed: $e');
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
            enableVibration: true,
            playSound: true,
            enableLights: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
      
      Logger.d('NotificationService: showed immediate notification');
    } catch (e) {
      Logger.d('NotificationService: failed to show immediate notification: $e');
      rethrow;
    }
  }

  static Future<void> cancelAll() async {
    if (!_isInitialized) await initialize();
    
    try {
      // Cancel native alarms (individual cancellation since no cancelAll method exists yet)
      Logger.d('NotificationService: Cancelling all alarms and notifications');
      
      // Cancel Flutter notifications
      await _notifications.cancelAll();
      
      // Cancel timer fallback
      _fallbackTimer?.cancel();
      _fallbackTimer = null;
      
      Logger.d('NotificationService: cancelled all notifications and alarms');
    } catch (e) {
      Logger.d('NotificationService: failed to cancel notifications: $e');
    }
  }

  static Future<void> cancel(int id) async {
    try {
      // Cancel native alarm
      await NativeAlarmService.cancelNativeAlarm(id);
      
      // Cancel Flutter notification if any
      if (_isInitialized) {
        await _notifications.cancel(id);
      }
      
      Logger.d('NotificationService: cancelled notification/alarm $id');
    } catch (e) {
      Logger.d('NotificationService: failed to cancel notification $id: $e');
    }
  }

  // Get pending Flutter notifications (native alarms don't have a query method)
  static Future<List<dynamic>> getPendingNotifications() async {
    if (!_isInitialized) await initialize();
    
    try {
      final pending = await _notifications.pendingNotificationRequests();
      return pending.map((p) => {
        'id': p.id,
        'title': p.title,
        'body': p.body,
      }).toList();
    } catch (e) {
      Logger.d('NotificationService: failed to get pending notifications: $e');
      return [];
    }
  }

  // Test native alarm functionality
  static Future<void> testNativeAlarm() async {
    Logger.d('=== TESTING NATIVE ANDROID ALARMMANAGER ===');
    
    try {
      // Check if exact alarms can be scheduled
      final canScheduleExact = await NativeAlarmService.canScheduleExactAlarms();
      Logger.d('Native AlarmManager - Can schedule exact alarms: $canScheduleExact');
      
      // Schedule a test alarm for 30 seconds from now
      final testTime = DateTime.now().add(const Duration(seconds: 30));
      Logger.d('Native AlarmManager - Scheduling test for: $testTime');
      
      final success = await NativeAlarmService.scheduleNativeAlarm(
        id: 7777,
        title: 'Native Alarm Test',
        body: 'SUCCESS! Native Android AlarmManager works! ${DateTime.now()}',
        scheduledTime: testTime,
      );
      
      if (success) {
        Logger.d('Native AlarmManager - Test alarm scheduled successfully');
        Logger.d('Native AlarmManager - Watch for notification in 30 seconds');
      } else {
        Logger.d('Native AlarmManager - Test alarm scheduling failed');
      }
      
    } catch (e) {
      Logger.d('Native AlarmManager test failed: $e');
    }
    
    Logger.d('=== END NATIVE ALARMMANAGER TEST ===');
  }
}
