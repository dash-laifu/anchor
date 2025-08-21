package com.dash_laifu.anchor

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class NativeAlarmService {
    companion object {
        private const val CHANNEL_ID = "native_reminders"
        private const val CHANNEL_NAME = "Native Parking Reminders"
        private const val NOTIFICATION_ACTION = "com.dash_laifu.anchor.NOTIFICATION_ACTION"
        
        fun setupNativeAlarms(flutterEngine: FlutterEngine, context: Context) {
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "native_alarm")
            
            // Create notification channel
            createNotificationChannel(context)
            
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "scheduleAlarm" -> {
                        try {
                            val id = call.argument<Int>("id") ?: 0
                            val title = call.argument<String>("title") ?: "Reminder"
                            val body = call.argument<String>("body") ?: "Time's up!"
                            val timestamp = call.argument<Long>("timestamp") ?: 0L
                            
                            Log.d("NativeAlarm", "Scheduling alarm: ID=$id, timestamp=$timestamp")
                            Log.d("NativeAlarm", "Current time: ${System.currentTimeMillis()}")
                            Log.d("NativeAlarm", "Delay: ${timestamp - System.currentTimeMillis()}ms")
                            
                            val success = scheduleAlarm(context, id, title, body, timestamp)
                            result.success(success)
                        } catch (e: Exception) {
                            Log.e("NativeAlarm", "Failed to schedule alarm", e)
                            result.error("ALARM_ERROR", e.message, null)
                        }
                    }
                    "cancelAlarm" -> {
                        try {
                            val id = call.argument<Int>("id") ?: 0
                            cancelAlarm(context, id)
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e("NativeAlarm", "Failed to cancel alarm", e)
                            result.error("CANCEL_ERROR", e.message, null)
                        }
                    }
                    "canScheduleExact" -> {
                        try {
                            val canSchedule = canScheduleExactAlarms(context)
                            Log.d("NativeAlarm", "Can schedule exact alarms: $canSchedule")
                            result.success(canSchedule)
                        } catch (e: Exception) {
                            Log.e("NativeAlarm", "Failed to check exact alarm permission", e)
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
        
        private fun createNotificationChannel(context: Context) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Native parking reminder notifications"
                    enableVibration(true)
                    enableLights(true)
                }
                
                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.createNotificationChannel(channel)
                Log.d("NativeAlarm", "Notification channel created")
            }
        }
        
        private fun scheduleAlarm(context: Context, id: Int, title: String, body: String, timestamp: Long): Boolean {
            return try {
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                
                // Create intent for the alarm receiver
                val intent = Intent(context, AlarmReceiver::class.java).apply {
                    action = NOTIFICATION_ACTION
                    putExtra("id", id)
                    putExtra("title", title)
                    putExtra("body", body)
                }
                
                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    id,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                
                // Check if we can schedule exact alarms
                val canScheduleExact = canScheduleExactAlarms(context)
                Log.d("NativeAlarm", "Can schedule exact alarms: $canScheduleExact")
                
                if (canScheduleExact) {
                    // Use setExactAndAllowWhileIdle for maximum reliability
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        timestamp,
                        pendingIntent
                    )
                    Log.d("NativeAlarm", "Scheduled EXACT alarm for $timestamp")
                } else {
                    // Fallback to inexact alarm
                    alarmManager.set(
                        AlarmManager.RTC_WAKEUP,
                        timestamp,
                        pendingIntent
                    )
                    Log.d("NativeAlarm", "Scheduled INEXACT alarm for $timestamp")
                }
                
                true
            } catch (e: Exception) {
                Log.e("NativeAlarm", "Failed to schedule alarm", e)
                false
            }
        }
        
        private fun cancelAlarm(context: Context, id: Int) {
            try {
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                val intent = Intent(context, AlarmReceiver::class.java).apply {
                    action = NOTIFICATION_ACTION
                }
                
                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    id,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                
                alarmManager.cancel(pendingIntent)
                Log.d("NativeAlarm", "Cancelled alarm $id")
            } catch (e: Exception) {
                Log.e("NativeAlarm", "Failed to cancel alarm", e)
            }
        }
        
        private fun canScheduleExactAlarms(context: Context): Boolean {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                alarmManager.canScheduleExactAlarms()
            } else {
                true // Pre-Android 12 doesn't need permission
            }
        }
    }
}

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "com.dash_laifu.anchor.NOTIFICATION_ACTION") {
            val id = intent.getIntExtra("id", 0)
            val title = intent.getStringExtra("title") ?: "Reminder"
            val body = intent.getStringExtra("body") ?: "Time's up!"
            
            Log.d("AlarmReceiver", "Alarm received: ID=$id, title=$title")
            showNotification(context, id, title, body)
        }
    }
    
    private fun showNotification(context: Context, id: Int, title: String, body: String) {
        try {
            val notification = NotificationCompat.Builder(context, "native_reminders")
                .setContentTitle(title)
                .setContentText(body)
                .setSmallIcon(android.R.drawable.ic_dialog_info) // Use system icon for now
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .setVibrate(longArrayOf(0, 500, 200, 500))
                .setDefaults(NotificationCompat.DEFAULT_ALL)
                .build()
            
            val notificationManager = NotificationManagerCompat.from(context)
            notificationManager.notify(id, notification)
            
            Log.d("AlarmReceiver", "Notification shown: ID=$id")
        } catch (e: Exception) {
            Log.e("AlarmReceiver", "Failed to show notification", e)
        }
    }
}
