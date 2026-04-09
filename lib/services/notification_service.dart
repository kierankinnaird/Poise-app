// Singleton so init() is only called once regardless of how many times
// the service is instantiated across the app.
// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const int _rescreenNotificationId = 1001;

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // I request permissions at the point the user enables the toggle in
    // ProfileScreen, not upfront -- less intrusive.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(initSettings);
  }

  // Returns true if permission was granted (or already granted on Android).
  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }
    return true;
  }

  Future<void> scheduleRescreenReminder() async {
    const androidDetails = AndroidNotificationDetails(
      'poise_rescreen',
      'Rescreen Reminders',
      channelDescription: 'Weekly movement screen reminders',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.periodicallyShow(
      _rescreenNotificationId,
      'Time for your Poise screen',
      'Check your movement quality -- it only takes 2 minutes.',
      RepeatInterval.weekly,
      details,
      androidScheduleMode: AndroidScheduleMode.inexact,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
