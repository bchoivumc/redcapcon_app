import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../services/schedule_service.dart';
import '../models/session.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  final ScheduleService _scheduleService = ScheduleService();

  bool _notificationsEnabled = true;
  bool _isLoading = true;
  bool _canScheduleExactAlarms = true;
  List<PendingNotificationRequest> _pendingNotifications = [];
  List<Session> _savedSessions = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Load notification enabled preference
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notifications_enabled') ?? true;

      // Check if we can schedule exact alarms (Android 12+)
      final canSchedule = await _notificationService.canScheduleExactAlarms();

      // Load pending notifications
      final pending = await _notificationService.getPendingNotifications();

      // Load saved sessions
      final savedIds = await _scheduleService.getSavedSessionIds();
      final allSessions = await _scheduleService.fetchSchedule(year: 2026);
      final saved = allSessions.where((s) => savedIds.contains(s.id)).toList();

      if (!mounted) return;
      setState(() {
        _notificationsEnabled = enabled;
        _canScheduleExactAlarms = canSchedule;
        _pendingNotifications = pending;
        _savedSessions = saved;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading settings: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);

    if (!mounted) return;
    setState(() => _notificationsEnabled = value);

    if (value) {
      // Re-schedule all notifications for saved sessions
      for (final session in _savedSessions) {
        await _notificationService.scheduleSessionReminder(session);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications enabled and scheduled')),
        );
      }
    } else {
      // Cancel all notifications
      await _notificationService.cancelAllReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications disabled')),
        );
      }
    }

    await _loadSettings();
  }

  Future<void> _cancelNotification(int id) async {
    // Find the session with this notification ID
    final session = _savedSessions.firstWhere(
      (s) => s.id.hashCode == id,
      orElse: () => _savedSessions.first,
    );

    // Cancel only the notification, keep the session in schedule
    await _notificationService.cancelSessionReminder(session);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification cancelled for "${session.title}"')),
      );
    }

    await _loadSettings();
  }

  Future<void> _rescheduleAll() async {
    await _notificationService.cancelAllReminders();

    for (final session in _savedSessions) {
      await _notificationService.scheduleSessionReminder(session);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications rescheduled')),
      );
    }

    await _loadSettings();
  }

  String _formatNotificationTime(int? id) {
    if (id == null) return 'Unknown';

    // Find the session with matching ID
    final session = _savedSessions.firstWhere(
      (s) => s.id.hashCode == id,
      orElse: () => _savedSessions.first,
    );

    final notificationTime = session.startTime.subtract(const Duration(minutes: 5));
    return DateFormat('MMM d, yyyy - h:mm a').format(notificationTime);
  }

  String _getSessionTitle(int? id) {
    if (id == null) return 'Unknown Session';

    try {
      final session = _savedSessions.firstWhere(
        (s) => s.id.hashCode == id,
      );
      return session.title;
    } catch (e) {
      return 'Unknown Session';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        actions: [
          if (!_isLoading && _savedSessions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _rescheduleAll,
              tooltip: 'Reschedule All',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSettings,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Enable/Disable Toggle
                  Card(
                    child: SwitchListTile(
                      title: const Text('Enable Notifications'),
                      subtitle: const Text('Receive reminders 5 minutes before sessions'),
                      value: _notificationsEnabled,
                      onChanged: _toggleNotifications,
                      secondary: Icon(
                        _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                        color: _notificationsEnabled ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Permission Warning (Android 12+)
                  if (!_canScheduleExactAlarms)
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Permission Required',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Exact alarm permission is required for precise notifications on Android 12+.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange.shade800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () async {
                                await _notificationService.requestPermissions();
                                await _loadSettings();
                              },
                              icon: const Icon(Icons.settings),
                              label: const Text('Enable Exact Alarms'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!_canScheduleExactAlarms) const SizedBox(height: 16),

                  // Statistics
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  '${_savedSessions.length}',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Saved Sessions',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  '${_pendingNotifications.length}',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Pending Alerts',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Pending Notifications List
                  if (_pendingNotifications.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Pending Notifications',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _savedSessions.isEmpty
                                  ? 'Add sessions to your schedule to receive reminders'
                                  : 'Notifications may have already passed or been disabled',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    Text(
                      'Scheduled Notifications',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ..._pendingNotifications.map((notification) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Icon(
                              Icons.alarm,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          title: Text(
                            _getSessionTitle(notification.id),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatNotificationTime(notification.id),
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                notification.body ?? 'Reminder',
                                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.notifications_off_outlined, color: Colors.red),
                            onPressed: () => _cancelNotification(notification.id),
                            tooltip: 'Cancel notification only',
                          ),
                          isThreeLine: true,
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 24),

                  // Info Card
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'About Notifications',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '• Notifications are sent 5 minutes before each session starts\n'
                                  '• Time zone: Central Daylight Time (CDT)\n'
                                  '• Only future sessions will have notifications\n'
                                  '• Pull down to refresh the notification list',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
