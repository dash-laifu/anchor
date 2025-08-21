import 'package:flutter/services.dart';
import 'package:anchor/utils/logger.dart';

class NativeAlarmService {
  static const MethodChannel _channel = MethodChannel('native_alarm');
  
  /// Schedule a native alarm using Android's AlarmManager directly
  static Future<bool> scheduleNativeAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      final timestamp = scheduledTime.millisecondsSinceEpoch;
      Logger.d('NativeAlarmService: Scheduling native alarm');
      Logger.d('  ID: $id');
      Logger.d('  Title: $title');
      Logger.d('  Scheduled time: $scheduledTime');
      Logger.d('  Timestamp: $timestamp');
      Logger.d('  Current time: ${DateTime.now()}');
      Logger.d('  Delay: ${scheduledTime.difference(DateTime.now()).inSeconds}s');
      
      final result = await _channel.invokeMethod('scheduleAlarm', {
        'id': id,
        'title': title,
        'body': body,
        'timestamp': timestamp,
      });
      
      Logger.d('NativeAlarmService: Native alarm scheduled successfully: $result');
      return result as bool? ?? false;
    } catch (e) {
      Logger.d('NativeAlarmService: Failed to schedule native alarm: $e');
      return false;
    }
  }
  
  /// Cancel a native alarm
  static Future<bool> cancelNativeAlarm(int id) async {
    try {
      final result = await _channel.invokeMethod('cancelAlarm', {'id': id});
      Logger.d('NativeAlarmService: Cancelled native alarm $id');
      return result as bool? ?? false;
    } catch (e) {
      Logger.d('NativeAlarmService: Failed to cancel native alarm: $e');
      return false;
    }
  }
  
  /// Check if exact alarms can be scheduled
  static Future<bool> canScheduleExactAlarms() async {
    try {
      final result = await _channel.invokeMethod('canScheduleExact');
      Logger.d('NativeAlarmService: Can schedule exact alarms: $result');
      return result as bool? ?? false;
    } catch (e) {
      Logger.d('NativeAlarmService: Failed to check exact alarm permission: $e');
      return false;
    }
  }
  
  /// Test native alarm with short delay
  static Future<bool> testNativeAlarm() async {
    final testTime = DateTime.now().add(const Duration(seconds: 10));
    return await scheduleNativeAlarm(
      id: 9999,
      title: 'Native Alarm Test',
      body: 'If you see this, native alarms work! Time: ${DateTime.now()}',
      scheduledTime: testTime,
    );
  }
}
