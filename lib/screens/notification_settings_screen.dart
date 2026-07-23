import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/schedule_service.dart';
import '../models/session.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();
  final ScheduleService _scheduleService = ScheduleService();

  bool _notificationsEnabled = true;
  bool _isLoading = true;
  bool _canScheduleExactAlarms = true;
  Set<String> _scheduledSessionIds = {};
  String _lastDiag = '';
  List<Session> _savedSessions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _onAppResumed();
  }

  Future<void> _onAppResumed() async {
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notifications_enabled') ?? true;
      if (enabled) await _notificationService.requestPermissions();
      final canSchedule = await _notificationService.canScheduleExactAlarms();
      final scheduledIds = await _notificationService.getScheduledSessionIds();

      final savedIds = await _scheduleService.getSavedSessionIds();
      final allSessions = await _scheduleService.fetchSchedule(year: 2026);
      final saved = allSessions.where((s) => savedIds.contains(s.id)).toList();

      if (!mounted) return;
      setState(() {
        _notificationsEnabled = enabled;
        _canScheduleExactAlarms = canSchedule;
        _scheduledSessionIds = scheduledIds;
        _savedSessions = saved;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _scheduleAllReminders({bool showSnackbar = false}) async {
    await _notificationService.requestPermissions();
    final result = await _notificationService.scheduleAllReminders(_savedSessions);
    if (mounted) setState(() => _lastDiag = result.summary);
    await _loadSettings();
    if (showSnackbar && mounted) {
      final msg = result.scheduled > 0
          ? '${result.scheduled} reminder${result.scheduled == 1 ? '' : 's'} scheduled'
          : 'No upcoming sessions to schedule';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);

    if (!mounted) return;
    setState(() => _notificationsEnabled = value);

    if (value) {
      await _notificationService.requestPermissions();
      await _scheduleAllReminders(showSnackbar: true);
    } else {
      await _notificationService.cancelAllReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications disabled')),
        );
      }
      await _loadSettings();
    }
  }

  Future<void> _cancelNotification(Session session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Notification'),
        content: Text('Cancel reminder for "${session.title}"?\n\nThe session stays in your schedule.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Reminder'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _notificationService.cancelSessionReminder(session);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder cancelled for "${session.title}"')),
      );
    }
    await _loadSettings();
  }

  String _notifTimeLabel(Session session) {
    final t = session.startTime.toUtc().subtract(const Duration(minutes: 5));
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour < 12 ? 'AM' : 'PM';
    final month = DateFormat('MMM').format(DateTime.utc(t.year, t.month, t.day));
    return '$month ${t.day}, $h:$m $ampm CDT';
  }

  @override
  Widget build(BuildContext context) {
    final scheduledCount = _scheduledSessionIds.length;
    final hasScheduled = scheduledCount > 0;

    final scheduledSessions = _savedSessions
        .where((s) => _scheduledSessionIds.contains(s.id))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSettings,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
                children: [
                  // Enable/Disable Toggle
                  Card(
                    child: SwitchListTile(
                      title: const Text('Enable Notifications'),
                      subtitle: const Text('Receive reminders 5 minutes before sessions'),
                      value: _notificationsEnabled,
                      onChanged: _toggleNotifications,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Permission Warning (Android 12+)
                  if (!_canScheduleExactAlarms) ...[
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
                              style: TextStyle(fontSize: 14, color: Colors.orange.shade800),
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
                    const SizedBox(height: 16),
                  ],

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
                                const Text('Saved Sessions', style: TextStyle(fontSize: 12)),
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
                                  '$scheduledCount',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        color: hasScheduled ? Colors.green : Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                const Text('Scheduled Alerts', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Schedule All button + diagnostic
                  if (_savedSessions.isNotEmpty && _notificationsEnabled) ...[
                    FilledButton.icon(
                      onPressed: () => _scheduleAllReminders(showSnackbar: true),
                      icon: const Icon(Icons.notifications_active),
                      label: Text(hasScheduled ? 'Reschedule All' : 'Schedule All Reminders'),
                    ),
                    if (_lastDiag.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          _lastDiag,
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],

                  // Scheduled Notifications List
                  if (!hasScheduled)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.notifications_none, size: 56, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'No Reminders Scheduled',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _savedSessions.isEmpty
                                  ? 'Add sessions to your schedule to receive reminders'
                                  : 'Tap "Schedule All Reminders" above to set up alerts',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                    ...scheduledSessions.map((session) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              session.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(
                                  _notifTimeLabel(session),
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                Text(
                                  session.location,
                                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.notifications_off_outlined, color: Colors.red),
                              onPressed: () => _cancelNotification(session),
                              tooltip: 'Cancel this reminder',
                            ),
                            isThreeLine: true,
                          ),
                        )),
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
                                  style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
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
