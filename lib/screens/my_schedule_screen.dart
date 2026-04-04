import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/session.dart';
import '../services/schedule_service.dart';
import '../widgets/session_card.dart';
import 'notification_settings_screen.dart';

class MyScheduleScreen extends StatefulWidget {
  const MyScheduleScreen({super.key});

  @override
  State<MyScheduleScreen> createState() => MyScheduleScreenState();
}

class MyScheduleScreenState extends State<MyScheduleScreen> {
  final ScheduleService _scheduleService = ScheduleService();
  List<Session> _savedSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedSessions();
  }

  Future<void> _loadSavedSessions() async {
    setState(() => _isLoading = true);
    try {
      final allSessions = await _scheduleService.fetchSchedule();
      final savedIds = await _scheduleService.getSavedSessionIds();

      setState(() {
        _savedSessions = allSessions
            .where((session) => savedIds.contains(session.id))
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading schedule: $e')),
        );
      }
    }
  }

  Map<String, List<Session>> _groupSessionsByDate() {
    final Map<String, List<Session>> grouped = {};
    for (var session in _savedSessions) {
      grouped.putIfAbsent(session.dateKey, () => []).add(session);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedSessions = _groupSessionsByDate();
    final sortedDates = groupedSessions.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
              // Refresh the schedule when returning from settings
              _loadSavedSessions();
            },
            tooltip: 'Notification Settings',
          ),
          if (_savedSessions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadSavedSessions,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedSessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 64,
                        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No sessions saved',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Browse the agenda and bookmark sessions\nto create your personal schedule',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSavedSessions,
                  child: ListView.builder(
                    itemCount: sortedDates.length,
                    itemBuilder: (context, index) {
                      final dateKey = sortedDates[index];
                      final sessions = groupedSessions[dateKey]!;
                      final date = sessions.first.startTime;
                      final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            color: Theme.of(context).colorScheme.primaryContainer,
                            child: Text(
                              dateFormat.format(date),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          ...sessions.map((session) => Dismissible(
                                key: Key(session.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  color: Colors.red,
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  // Show confirmation dialog
                                  return await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Remove Session'),
                                      content: Text(
                                        'Remove "${session.title}" from your schedule?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text('Remove'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                onDismissed: (direction) async {
                                  final messenger = ScaffoldMessenger.of(context);

                                  // Remove the session
                                  await _scheduleService.removeSession(session.id, session: session);

                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Removed "${session.title}" from your schedule'),
                                      action: SnackBarAction(
                                        label: 'Undo',
                                        onPressed: () async {
                                          // Re-add the session
                                          await _scheduleService.saveSession(session.id, session: session);
                                          _loadSavedSessions();
                                        },
                                      ),
                                    ),
                                  );

                                  // Reload the list
                                  _loadSavedSessions();
                                },
                                child: SessionCard(
                                  session: session,
                                  onTap: () => _showSessionDetails(session),
                                ),
                              )),
                        ],
                      );
                    },
                  ),
                ),
    );
  }

  void _showSessionDetails(Session session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    session.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.access_time, session.timeRange),
                  _buildDetailRow(Icons.location_on, session.location),
                  if (session.speaker.isNotEmpty)
                    _buildDetailRow(Icons.person, session.speaker),
                  _buildDetailRow(Icons.category, session.type),
                  _buildDetailRow(Icons.people, session.audience),
                  const SizedBox(height: 16),
                  if (session.description.isNotEmpty) ...[
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      session.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  if (session.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: session.tags
                          .map((tag) => Chip(
                                label: Text(tag),
                                labelStyle: const TextStyle(fontSize: 12),
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await _scheduleService.removeSession(session.id);
                        await _loadSavedSessions();
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.bookmark_remove),
                      label: const Text('Remove from My Schedule'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
