import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Model defining a scheduled reminder time and message.
class ReminderSchedule {
  final int id;
  final int hour;
  final int minute;
  final String title;
  final String body;
  final bool isProductionEnabled;

  const ReminderSchedule({
    required this.id,
    required this.hour,
    required this.minute,
    required this.title,
    required this.body,
    this.isProductionEnabled = false,
  });
}

/// Optimized singleton service to manage local daily reminder notifications.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// ⚙️ PRODUCTION TOGGLE:
  /// Set to [true] when publishing to Google Play Store.
  /// When [true], only 9:00 AM and 10:00 PM notifications are scheduled.
  /// When [false], all 4 notifications (9 AM, 1 PM, 5 PM, 10 PM) are scheduled.
  static const bool isProduction = false;

  static const String _channelId = 'redpdf_daily_reminders';
  static const String _channelName = 'Daily Reminders';
  static const String _channelDescription =
      'Friendly reminders to compress and organize PDFs & photos';
  static const String _prefScheduleKey = 'redpdf_notification_schedule_version';
  static const int _scheduleVersion = 1;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// All configured reminder times.
  static const List<ReminderSchedule> _allSchedules = [
    ReminderSchedule(
      id: 101,
      hour: 9,
      minute: 0,
      title: "Start Your Day Light! 📄",
      body:
          "Got heavy PDFs or photos? Compress them in seconds to save phone storage.",
      isProductionEnabled: true, // 9:00 AM (Active in both dev and prod)
    ),
    ReminderSchedule(
      id: 102,
      hour: 13,
      minute: 0,
      title: "Need to Send Documents? 🚀",
      body:
          "Shrink large PDFs and images quickly for instant sharing on WhatsApp & Email.",
      isProductionEnabled: false, // 1:00 PM (Dev only)
    ),
    ReminderSchedule(
      id: 103,
      hour: 17,
      minute: 0,
      title: "Clean Up Phone Storage 💾",
      body:
          "Free up storage by compressing recent downloads and camera captures.",
      isProductionEnabled: false, // 5:00 PM (Dev only)
    ),
    ReminderSchedule(
      id: 104,
      hour: 22,
      minute: 0,
      title: "Wrap Up Your Day 🌙",
      body:
          "All files organized? Compress and archive your heavy files before winding down.",
      isProductionEnabled: true, // 10:00 PM (Active in both dev and prod)
    ),
  ];

  /// Get the active schedules based on [isProduction] mode.
  List<ReminderSchedule> get activeSchedules {
    if (isProduction) {
      return _allSchedules.where((s) => s.isProductionEnabled).toList();
    }
    return _allSchedules;
  }

  /// Initialize notification settings, timezone, and channels.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize Timezones
      tz.initializeTimeZones();
      try {
        final timezoneInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
      } catch (e) {
        developer.log(
          "Could not detect local timezone, falling back to local: $e",
          name: "NotificationService",
        );
      }

      // 2. Setup initialization settings
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // 3. Create high-priority notification channel for Android
      final androidPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlatform != null) {
        const channel = AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.defaultImportance,
        );
        await androidPlatform.createNotificationChannel(channel);
      }

      _isInitialized = true;

      // 4. Request permissions & schedule reminders in background
      _requestPermissionsAndSchedule();
    } catch (e, stackTrace) {
      developer.log(
        "Failed to initialize NotificationService: $e",
        name: "NotificationService",
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Asynchronously request notification permission and schedule reminders.
  Future<void> _requestPermissionsAndSchedule() async {
    try {
      final androidPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlatform != null) {
        await androidPlatform.requestNotificationsPermission();
      }

      await scheduleDailyReminders();
    } catch (e) {
      developer.log(
        "Error requesting permission / scheduling reminders: $e",
        name: "NotificationService",
      );
    }
  }

  /// Schedule the daily reminder notifications.
  /// Optimized with a cache check so we don't unnecessarily reschedule on every single app launch.
  Future<void> scheduleDailyReminders({bool force = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentConfigKey = "${_scheduleVersion}_prod_$isProduction";
      final savedConfig = prefs.getString(_prefScheduleKey);

      if (!force && savedConfig == currentConfigKey) {
        // Already scheduled for this mode and version
        return;
      }

      final active = activeSchedules;
      final activeIds = active.map((s) => s.id).toSet();

      // Cancel inactive schedules (e.g. 1 PM and 5 PM when in production)
      for (final schedule in _allSchedules) {
        if (!activeIds.contains(schedule.id)) {
          await _notificationsPlugin.cancel(id: schedule.id);
        }
      }

      // Notification details configuration
      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      // Schedule each active reminder
      for (final schedule in active) {
        final scheduledDate = _nextInstanceOfTime(schedule.hour, schedule.minute);

        await _notificationsPlugin.zonedSchedule(
          id: schedule.id,
          title: schedule.title,
          body: schedule.body,
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexact,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }

      await prefs.setString(_prefScheduleKey, currentConfigKey);
      developer.log(
        "Successfully scheduled ${active.length} daily reminder notifications (Production: $isProduction)",
        name: "NotificationService",
      );
    } catch (e, stackTrace) {
      developer.log(
        "Failed to schedule daily reminders: $e",
        name: "NotificationService",
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Calculates the next occurrence of [hour]:[minute] in the local timezone.
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Cancels all scheduled reminder notifications.
  Future<void> cancelAllReminders() async {
    try {
      for (final schedule in _allSchedules) {
        await _notificationsPlugin.cancel(id: schedule.id);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefScheduleKey);
    } catch (e) {
      developer.log("Error cancelling reminders: $e", name: "NotificationService");
    }
  }

  /// Trigger a test notification immediately to verify display and icon.
  Future<void> showTestNotification() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _notificationsPlugin.show(
      id: 999,
      title: "RedPDF Compress Active 📄",
      body: "Local notifications are set up and running smoothly!",
      notificationDetails: details,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print("Notification clicked: ${response.payload}");
    }
  }
}
