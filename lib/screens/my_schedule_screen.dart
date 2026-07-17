import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/session.dart';
import '../services/schedule_service.dart';
import '../services/pdf_export_service.dart';
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
  bool _isExporting = false;
  final Set<String> _deletingSessionIds = {};
  Set<String> _lockedSessionIds = {};
  Set<String> _conflictingSessionIds = {};

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
      final lockedIds = await _scheduleService.getLockedSessionIds();

      setState(() {
        _savedSessions = allSessions
            .where((session) => savedIds.contains(session.id))
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
        _lockedSessionIds = Set<String>.from(lockedIds);
        _conflictingSessionIds = _computeConflicts(_savedSessions);
        _isLoading = false;
        _deletingSessionIds.clear();
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

  Future<void> _exportPdf() async {
    if (_savedSessions.isEmpty) return;
    setState(() => _isExporting = true);
    try {
      await PdfExportService().shareSchedule(
        sessions: _savedSessions,
        lockedIds: _lockedSessionIds,
        conflictIds: _conflictingSessionIds,
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Set<String> _computeConflicts(List<Session> sessions) {
    final conflicts = <String>{};
    for (int i = 0; i < sessions.length; i++) {
      for (int j = i + 1; j < sessions.length; j++) {
        final a = sessions[i];
        final b = sessions[j];
        if (a.startTime.isBefore(b.endTime) && b.startTime.isBefore(a.endTime)) {
          conflicts.add(a.id);
          conflicts.add(b.id);
        }
      }
    }
    return conflicts;
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
          if (_savedSessions.isNotEmpty)
            _isExporting
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    onPressed: _exportPdf,
                    tooltip: 'Export as PDF',
                  ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
              _loadSavedSessions();
            },
            tooltip: 'Notification Settings',
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
              : ListView.builder(
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
                          ...sessions.map((session) {
                            final isDeleting = _deletingSessionIds.contains(session.id);
                            final isLocked = _lockedSessionIds.contains(session.id);
                            final isConflict = _conflictingSessionIds.contains(session.id);
                            return SessionCard(
                              session: session,
                              onTap: isDeleting ? null : () => _showSessionDetails(session, isLocked: isLocked),
                              isConflict: isConflict,
                              showBookmark: true,
                              isDeleting: isDeleting,
                              canRestore: isDeleting,
                              isLocked: isLocked,
                              onLockToggle: () async {
                                if (isLocked) {
                                  await _scheduleService.unlockSession(session.id);
                                  setState(() => _lockedSessionIds.remove(session.id));
                                } else {
                                  await _scheduleService.lockSession(session.id);
                                  setState(() => _lockedSessionIds.add(session.id));
                                }
                              },
                              onDelete: isLocked ? null : () async {
                                if (isDeleting) {
                                  setState(() => _deletingSessionIds.remove(session.id));
                                  await _scheduleService.saveSession(session.id, session: session);
                                } else {
                                  setState(() => _deletingSessionIds.add(session.id));
                                  await _scheduleService.removeSession(session.id, session: session);
                                }
                              },
                            );
                          }),
                        ],
                      );
                    },
                  ),
    );
  }

  void _showSessionDetails(Session session, {bool isLocked = false}) {
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
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        if (isLocked) {
                          await _scheduleService.unlockSession(session.id);
                          setState(() => _lockedSessionIds.remove(session.id));
                        } else {
                          await _scheduleService.lockSession(session.id);
                          setState(() => _lockedSessionIds.add(session.id));
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: Icon(isLocked ? Icons.lock_open : Icons.lock),
                      label: Text(isLocked ? 'Unlock session' : 'Lock session'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isLocked ? null : () async {
                        await _scheduleService.removeSession(session.id, session: session);
                        await _loadSavedSessions();
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.bookmark_remove),
                      label: Text(isLocked ? 'Locked — unlock to remove' : 'Remove from My Schedule'),
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
