import 'package:flutter/material.dart';
import 'package:anchor/services/notification_service.dart';
import 'package:anchor/utils/logger.dart';

class NotificationTestWidget extends StatelessWidget {
  const NotificationTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Notification Testing',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _testImmediateNotification(),
            child: const Text('Test Immediate Notification'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _testScheduledNotification(context, 1),
            child: const Text('Test 1 Min Reminder'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _testScheduledNotification(context, 2),
            child: const Text('Test 2 Min Reminder'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _testScheduledNotification(context, 5),
            child: const Text('Test 5 Min Reminder'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _clearAllNotifications(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade100,
            ),
            child: const Text('Clear All Notifications'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _testNativeAlarm(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Test Native Alarm (30s)'),
          ),
        ],
      ),
    );
  }

  static Future<void> _testImmediateNotification() async {
    try {
      await NotificationService.showImmediate(
        id: 999,
        title: 'Test Notification',
        body: 'This is a test notification shown immediately.',
      );
      Logger.d('Test: immediate notification sent');
    } catch (e) {
      Logger.d('Test: failed to send immediate notification: $e');
    }
  }

  static Future<void> _testScheduledNotification(BuildContext context, int minutes) async {
    try {
      final scheduledTime = DateTime.now().add(Duration(minutes: minutes));
      await NotificationService.scheduleReminder(
        id: 998,
        title: 'Test Reminder',
        body: 'This is a test reminder scheduled for $minutes minute(s) from now.',
        scheduledTime: scheduledTime,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scheduled test reminder for $minutes minute(s) from now'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      Logger.d('Test: scheduled notification for $minutes minutes');
    } catch (e) {
      Logger.d('Test: failed to schedule notification: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to schedule reminder'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  static Future<void> _clearAllNotifications(BuildContext context) async {
    try {
      await NotificationService.cancelAll();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications cleared'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      Logger.d('Test: cleared all notifications');
    } catch (e) {
      Logger.d('Test: failed to clear notifications: $e');
    }
  }

  static Future<void> _testNativeAlarm(BuildContext context) async {
    try {
      await NotificationService.testNativeAlarm();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Native alarm test started. Watch for notification in 30 seconds!'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
      }
      Logger.d('Test: native alarm test initiated');
    } catch (e) {
      Logger.d('Test: native alarm test failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Native alarm test failed'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
