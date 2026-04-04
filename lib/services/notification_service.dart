import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/session.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone database
      tz.initializeTimeZones();

      // Set Central Daylight Time as the default location
      tz.setLocalLocation(tz.getLocation('America/Chicago'));

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = initialized ?? false;
      print('Notification service initialized: $_initialized');
    } catch (e) {
      print('Error initializing notification service: $e');
      _initialized = false;
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - could navigate to session details
    print('Notification tapped: ${response.payload}');
  }

  /// Request notification permissions (mainly for iOS)
  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    // Request permissions for iOS
    final granted = await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Request permissions for Android 13+
    final androidGranted = await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Request exact alarm permission for Android 12+ (required for scheduled notifications)
    final exactAlarmPermission = await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    print('Exact alarm permission: $exactAlarmPermission');

    return granted ?? androidGranted ?? true;
  }

  /// Check if exact alarms are permitted (Android 12+)
  Future<bool> canScheduleExactAlarms() async {
    if (!_initialized) await initialize();

    try {
      final canSchedule = await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.canScheduleExactNotifications();

      return canSchedule ?? true; // Default to true for iOS and older Android
    } catch (e) {
      print('Error checking exact alarm permission: $e');
      return false;
    }
  }

  /// Schedule a notification 5 minutes before the session starts
  Future<void> scheduleSessionReminder(Session session) async {
    if (!_initialized) await initialize();

    // If initialization failed, return early
    if (!_initialized) {
      print('Cannot schedule notification - service not initialized');
      return;
    }

    // Check if we have permission for exact alarms (Android 12+)
    final canSchedule = await canScheduleExactAlarms();
    if (!canSchedule) {
      print('Cannot schedule notification - exact alarm permission not granted');
      print('Please enable exact alarms in system settings for precise notifications');
      return;
    }

    // Calculate notification time (5 minutes before session)
    final notificationTime = session.startTime.subtract(const Duration(minutes: 5));

    // Don't schedule if the notification time is in the past
    final now = DateTime.now();
    if (notificationTime.isBefore(now)) {
      print('Skipping notification for ${session.title} - time is in the past');
      return;
    }

    // Convert to timezone-aware datetime in CDT
    final tzNotificationTime = tz.TZDateTime.from(notificationTime, tz.getLocation('America/Chicago'));

    // Create notification details
    const androidDetails = AndroidNotificationDetails(
      'session_reminders',
      'Session Reminders',
      channelDescription: 'Notifications for upcoming sessions',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule the notification with error handling
    try {
      await _notifications.zonedSchedule(
        session.id.hashCode, // Use session ID hash as notification ID
        'Session Starting Soon!',
        '${session.title} starts in 5 minutes at ${session.location}',
        tzNotificationTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: session.id,
      );

      print('Scheduled notification for ${session.title} at $tzNotificationTime CDT');
    } catch (e) {
      print('Error scheduling notification: $e');
      // Don't throw - just log the error so the app continues working
    }
  }

  /// Cancel a notification for a session
  Future<void> cancelSessionReminder(Session session) async {
    if (!_initialized) await initialize();

    // If initialization failed, return early
    if (!_initialized) {
      print('Cannot cancel notification - service not initialized');
      return;
    }

    try {
      await _notifications.cancel(session.id.hashCode);
      print('Cancelled notification for ${session.title}');
    } catch (e) {
      print('Error cancelling notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllReminders() async {
    if (!_initialized) await initialize();

    // If initialization failed, return early
    if (!_initialized) {
      print('Cannot cancel all notifications - service not initialized');
      return;
    }

    try {
      await _notifications.cancelAll();
      print('Cancelled all notifications');
    } catch (e) {
      print('Error cancelling all notifications: $e');
    }
  }

  /// Get all pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_initialized) await initialize();

    // If initialization failed, return empty list
    if (!_initialized) {
      print('Cannot get pending notifications - service not initialized');
      return [];
    }

    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      print('Error getting pending notifications: $e');
      return [];
    }
  }
}
