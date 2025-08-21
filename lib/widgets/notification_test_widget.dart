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
            onPressed: () => _showPendingNotifications(context),
            child: const Text('Show Pending Notifications'),
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
            onPressed: () => _debugNotificationStatus(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade100,
            ),
            child: const Text('Debug Notification System'),
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

  static Future<void> _showPendingNotifications(BuildContext context) async {
    try {
      final pending = await NotificationService.getPendingNotifications();
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Pending Notifications'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: pending.isEmpty
                      ? [const Text('No pending notifications')]
                      : pending.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text('ID: ${p.id}\nTitle: ${p.title ?? '-'}\nBody: ${p.body ?? '-'}'),
                        )).toList(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
      Logger.d('Test: found ${pending.length} pending notifications');
    } catch (e) {
      Logger.d('Test: failed to get pending notifications: $e');
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

  static Future<void> _debugNotificationStatus() async {
    try {
      await NotificationService.debugNotificationStatus();
      Logger.d('Debug: notification status check completed');
    } catch (e) {
      Logger.d('Debug: notification status check failed: $e');
    }
  }
}
