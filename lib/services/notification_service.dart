import 'dart:developer' as dev;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/session.dart';

class ScheduleResult {
  final int scheduled;
  final int past;
  final int failed;
  final String nowCdt;
  final String? firstError;

  const ScheduleResult({
    required this.scheduled,
    required this.past,
    required this.failed,
    required this.nowCdt,
    this.firstError,
  });

  String get summary {
    final parts = <String>['Scheduled: $scheduled'];
    if (past > 0) parts.add('Past: $past');
    if (failed > 0) parts.add('Failed: $failed');
    if (firstError != null) {
      final e = firstError!.length > 80 ? '${firstError!.substring(0, 80)}…' : firstError!;
      parts.add('Error: $e');
    }
    return parts.join(' | ');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String? _lastScheduleError;

  static const _scheduledCountKey = 'notification_scheduled_count';
  static const _scheduledIdsKey = 'notification_scheduled_ids';

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('America/Chicago'));

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // Do NOT request permissions here — that happens later, on demand.
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      await _notifications.initialize(
        InitializationSettings(android: androidSettings, iOS: iosSettings),
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      // iOS returns false when all request*Permission are false (expected — we
      // request permissions separately). Treat any non-throwing return as success.
      _initialized = true;

      // Eagerly probe for corrupt stored notification data. If the plugin's
      // SharedPreferences store has stale entries (e.g. after a plugin upgrade
      // that added a required "type" field), the ScheduledNotificationBootReceiver
      // will crash on every device reboot. Calling cancelAll() here clears that
      // data so the next reboot is safe.
      if (_initialized) {
        try {
          await _notifications.pendingNotificationRequests();
        } catch (_) {
          try { await _notifications.cancelAll(); } catch (_) {}
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_scheduledCountKey, 0);
        }
      }
    } catch (e) {
      _lastScheduleError = 'Init failed: $e';
      _initialized = false;
    }
  }

  void _onNotificationTapped(NotificationResponse response) {}

  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    final granted = await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    final androidGranted = await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    return granted ?? androidGranted ?? true;
  }

  Future<bool> canScheduleExactAlarms() async {
    if (!_initialized) await initialize();
    try {
      final canSchedule = await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.canScheduleExactNotifications();
      return canSchedule ?? true;
    } catch (_) {
      return false;
    }
  }

  // Opens the Alarms & Reminders settings screen so the user can grant
  // SCHEDULE_EXACT_ALARM. Call this only from an explicit user action — NOT
  // from _loadSettings(), or returning from settings will trigger a loop.
  Future<void> requestExactAlarmPermission() async {
    if (!_initialized) await initialize();
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  Future<bool> scheduleSessionReminder(Session session) async {
    if (!_initialized) await initialize();
    if (!_initialized) return false;

    final notificationTime = session.startTime.subtract(const Duration(minutes: 5));

    // Session times are stored as CDT local values (the hour/minute components represent
    // Central time, regardless of any UTC/Z suffix in the source data). Build the
    // TZDateTime directly from those components so we get the correct CDT moment.
    final chicagoLocation = tz.getLocation('America/Chicago');
    final tzNotificationTime = tz.TZDateTime(
      chicagoLocation,
      notificationTime.year,
      notificationTime.month,
      notificationTime.day,
      notificationTime.hour,
      notificationTime.minute,
      notificationTime.second,
    );

    if (tzNotificationTime.isBefore(tz.TZDateTime.now(chicagoLocation))) return false;

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

    try {
      await _notifications.zonedSchedule(
        session.id.hashCode,
        'Session Starting Soon!',
        '${session.title} starts in 5 minutes at ${session.location}',
        tzNotificationTime,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        // alarmClock mode uses AlarmManager.setAlarmClock() — always fires on time,
        // no SCHEDULE_EXACT_ALARM permission needed, no per-call quota on Android 12+.
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        payload: session.id,
      );
      final prefs = await SharedPreferences.getInstance();
      final ids = Set<String>.from(prefs.getStringList(_scheduledIdsKey) ?? []);
      ids.add(session.id);
      await prefs.setStringList(_scheduledIdsKey, ids.toList());
      return true;
    } catch (e) {
      dev.log('zonedSchedule error for "${session.title}": $e', name: 'Notifications');
      _lastScheduleError = e.toString();
      return false;
    }
  }

  Future<void> cancelSessionReminder(Session session) async {
    if (!_initialized) await initialize();
    if (!_initialized) return;

    try {
      await _notifications.cancel(session.id.hashCode);
      final prefs = await SharedPreferences.getInstance();
      final ids = Set<String>.from(prefs.getStringList(_scheduledIdsKey) ?? []);
      ids.remove(session.id);
      await prefs.setStringList(_scheduledIdsKey, ids.toList());
      await prefs.setInt(_scheduledCountKey, ids.length);
    } catch (_) {}
  }

  Future<void> cancelAllReminders() async {
    if (!_initialized) await initialize();
    if (!_initialized) return;

    try {
      await _notifications.cancelAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_scheduledIdsKey, []);
      await prefs.setInt(_scheduledCountKey, 0);
    } catch (_) {}
  }

  Future<Set<String>> getScheduledSessionIds() async {
    final prefs = await SharedPreferences.getInstance();
    return Set<String>.from(prefs.getStringList(_scheduledIdsKey) ?? []);
  }

  // Returns only IDs whose notification time is still in the future, and
  // prunes past ones from SharedPreferences so the count stays accurate.
  Future<Set<String>> getActiveScheduledIds(List<Session> sessions) async {
    if (!_initialized) await initialize();
    final prefs = await SharedPreferences.getInstance();
    var ids = Set<String>.from(prefs.getStringList(_scheduledIdsKey) ?? []);

    final chicagoLocation = tz.getLocation('America/Chicago');
    final now = tz.TZDateTime.now(chicagoLocation);
    final toRemove = <String>{};

    for (final session in sessions) {
      if (!ids.contains(session.id)) continue;
      final notifTime = session.startTime.subtract(const Duration(minutes: 5));
      final tzNotifTime = tz.TZDateTime(
        chicagoLocation,
        notifTime.year, notifTime.month, notifTime.day,
        notifTime.hour, notifTime.minute, notifTime.second,
      );
      if (tzNotifTime.isBefore(now)) toRemove.add(session.id);
    }

    if (toRemove.isNotEmpty) {
      ids = ids.difference(toRemove);
      await prefs.setStringList(_scheduledIdsKey, ids.toList());
      await prefs.setInt(_scheduledCountKey, ids.length);
    }

    return ids;
  }

  Future<int> getScheduledCount() async {
    final ids = await getScheduledSessionIds();
    return ids.length;
  }

  /// Schedules reminders for all [sessions].
  /// Returns a [ScheduleResult] with counts and current CDT time for diagnostics.
  Future<ScheduleResult> scheduleAllReminders(List<Session> sessions) async {
    if (!_initialized) await initialize();

    // Reset the tracked ID set before rescheduling so stale IDs don't linger.
    final prefsReset = await SharedPreferences.getInstance();
    await prefsReset.setStringList(_scheduledIdsKey, []);

    final chicagoLocation = tz.getLocation('America/Chicago');
    final now = tz.TZDateTime.now(chicagoLocation);
    final nowStr = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')} '
        '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')} CDT';

    dev.log('scheduleAllReminders: now=$nowStr, sessions=${sessions.length}, initialized=$_initialized', name: 'Notifications');

    if (!_initialized) {
      return ScheduleResult(scheduled: 0, past: 0, failed: sessions.length, nowCdt: nowStr, firstError: _lastScheduleError ?? 'Not initialized');
    }

    int scheduled = 0;
    int past = 0;
    int failed = 0;
    String? firstError;

    for (final session in sessions) {
      final notifTime = session.startTime.subtract(const Duration(minutes: 5));
      final tzNotifTime = tz.TZDateTime(
        chicagoLocation,
        notifTime.year,
        notifTime.month,
        notifTime.day,
        notifTime.hour,
        notifTime.minute,
        notifTime.second,
      );
      final isPast = tzNotifTime.isBefore(now);

      dev.log(
        '  "${session.title.length > 30 ? session.title.substring(0, 30) : session.title}": '
        'notif=$tzNotifTime, isPast=$isPast',
        name: 'Notifications',
      );

      if (isPast) {
        past++;
        continue;
      }

      _lastScheduleError = null;
      final ok = await scheduleSessionReminder(session);
      if (ok) { scheduled++; } else { failed++; firstError ??= _lastScheduleError; }
    }

    dev.log('Result: scheduled=$scheduled, past=$past, failed=$failed', name: 'Notifications');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_scheduledCountKey, scheduled);
    return ScheduleResult(scheduled: scheduled, past: past, failed: failed, nowCdt: nowStr, firstError: firstError);

  }
}
