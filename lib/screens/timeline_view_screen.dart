import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/session.dart';
import '../services/schedule_service.dart';

class TimelineViewScreen extends StatefulWidget {
  final int selectedYear;

  const TimelineViewScreen({
    super.key,
    this.selectedYear = 2026,
  });

  @override
  State<TimelineViewScreen> createState() => TimelineViewScreenState();
}

class TimelineViewScreenState extends State<TimelineViewScreen> {
  final ScheduleService _scheduleService = ScheduleService();
  List<Session> _allSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  @override
  void didUpdateWidget(TimelineViewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedYear != widget.selectedYear) {
      _loadSchedule();
    }
  }

  Future<void> _loadSchedule() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final sessions = await _scheduleService.fetchSchedule(year: widget.selectedYear);

    if (!mounted) return;
    setState(() {
      _allSessions = sessions;
      _isLoading = false;
    });
  }

  Map<String, Map<String, List<Session>>> _groupByTimeSlots() {
    // First, group sessions by date
    final sessionsByDate = <String, List<Session>>{};
    for (var session in _allSessions) {
      final dateKey = session.dateKey;
      sessionsByDate.putIfAbsent(dateKey, () => []).add(session);
    }

    // Sort sessions within each date
    for (var sessions in sessionsByDate.values) {
      sessions.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    // Create time slots and group sessions
    final timeSlots = <String, Map<String, List<Session>>>{};
    
    for (var date in sessionsByDate.keys) {
      final sessions = sessionsByDate[date]!;
      
      for (var session in sessions) {
        final startHour = session.startTime.hour;
        final startMinute = session.startTime.minute;
        
        // Create time slot key (e.g., "08:00", "09:30")
        final timeSlot = '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
        
        // Initialize time slot if needed
        timeSlots.putIfAbsent(timeSlot, () => {});
        
        // Add session to the appropriate date within this time slot
        timeSlots[timeSlot]!.putIfAbsent(date, () => []).add(session);
      }
    }

    return timeSlots;
  }

  List<String> _getSortedTimeSlots(Map<String, Map<String, List<Session>>> timeSlots) {
    final slots = timeSlots.keys.toList();
    slots.sort((a, b) {
      final aTime = TimeOfDay(
        hour: int.parse(a.split(':')[0]),
        minute: int.parse(a.split(':')[1]),
      );
      final bTime = TimeOfDay(
        hour: int.parse(b.split(':')[0]),
        minute: int.parse(b.split(':')[1]),
      );
      
      if (aTime.hour != bTime.hour) {
        return aTime.hour.compareTo(bTime.hour);
      }
      return aTime.minute.compareTo(bTime.minute);
    });
    return slots;
  }

  List<String> _getSortedDates() {
    final dates = _allSessions.map((s) => s.dateKey).toSet().toList();
    dates.sort();
    return dates;
  }

  String _formatDate(String dateKey) {
    try {
      final date = DateTime.parse(dateKey);
      return DateFormat('EEE, MMM d').format(date);
    } catch (e) {
      return dateKey;
    }
  }

  String _formatTimeSlot(String timeSlot) {
    try {
      final parts = timeSlot.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      final time = TimeOfDay(hour: hour, minute: minute);
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      
      return DateFormat('h:mm a').format(dt);
    } catch (e) {
      return timeSlot;
    }
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FutureBuilder<bool>(
                      future: _scheduleService.isSessionSaved(session.id),
                      builder: (context, snapshot) {
                        final isSaved = snapshot.data ?? false;
                        return FilledButton.icon(
                          onPressed: () async {
                            await _scheduleService.toggleSession(session.id, session: session);
                            setState(() {});
                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: Icon(isSaved ? Icons.bookmark_remove : Icons.bookmark_add),
                          label: Text(isSaved ? 'Remove from My Schedule' : 'Add to My Schedule'),
                        );
                      },
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Timeline View'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final timeSlots = _groupByTimeSlots();
    final sortedTimeSlots = _getSortedTimeSlots(timeSlots);
    final sortedDates = _getSortedDates();

    return Scaffold(
      appBar: AppBar(
        title: Text('Timeline View - ${widget.selectedYear}'),
      ),
      body: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with dates
                Row(
                  children: [
                    // Time column header
                    SizedBox(
                      width: 100,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Time',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                    // Date headers
                    ...sortedDates.map((date) {
                      return SizedBox(
                        width: 220,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatDate(date),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 8),
                // Time slot rows
                ...sortedTimeSlots.map((timeSlot) {
                  final sessionsInSlot = timeSlots[timeSlot]!;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time label
                        SizedBox(
                          width: 100,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              _formatTimeSlot(timeSlot),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                        // Sessions for each date
                        ...sortedDates.map((date) {
                          final sessions = sessionsInSlot[date] ?? [];
                          
                          return SizedBox(
                            width: 220,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: sessions.isEmpty
                                  ? Container(
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    )
                                  : Column(
                                      children: sessions.map((session) {
                                        return FutureBuilder<bool>(
                                          future: _scheduleService.isSessionSaved(session.id),
                                          builder: (context, snapshot) {
                                            final isSaved = snapshot.data ?? false;

                                            return GestureDetector(
                                              onTap: () => _showSessionDetails(session),
                                              child: Container(
                                                margin: const EdgeInsets.only(bottom: 4),
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: isSaved
                                                      ? Colors.blue.shade100
                                                      : Theme.of(context).colorScheme.secondaryContainer,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: isSaved
                                                        ? Colors.blue.shade400
                                                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                                    width: isSaved ? 2 : 1,
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        if (isSaved)
                                                          Padding(
                                                            padding: const EdgeInsets.only(right: 4),
                                                            child: Icon(
                                                              Icons.bookmark,
                                                              size: 14,
                                                              color: Colors.blue.shade700,
                                                            ),
                                                          ),
                                                        Expanded(
                                                          child: Text(
                                                            session.title,
                                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                                  fontWeight: FontWeight.bold,
                                                                  color: isSaved
                                                                      ? Colors.blue.shade900
                                                                      : null,
                                                                ),
                                                            maxLines: 2,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      session.timeRange,
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                            fontSize: 10,
                                                            color: isSaved
                                                                ? Colors.blue.shade800
                                                                : Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
                                                          ),
                                                    ),
                                                    if (session.location.isNotEmpty) ...[
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        session.location,
                                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                              fontSize: 10,
                                                              color: isSaved
                                                                  ? Colors.blue.shade800
                                                                  : Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
                                                            ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      }).toList(),
                                    ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
