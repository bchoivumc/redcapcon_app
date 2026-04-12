import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/session.dart';
import '../services/schedule_service.dart';
import '../widgets/session_card.dart';
import '../widgets/filter_bottom_sheet.dart';
import 'settings_screen.dart';

class AgendaScreen extends StatefulWidget {
  final int selectedYear;
  final ValueChanged<int>? onYearChanged;

  const AgendaScreen({
    super.key,
    this.selectedYear = 2026,
    this.onYearChanged,
  });

  @override
  State<AgendaScreen> createState() => AgendaScreenState();
}

class AgendaScreenState extends State<AgendaScreen> {
  final ScheduleService _scheduleService = ScheduleService();
  List<Session> _allSessions = [];
  List<Session> _filteredSessions = [];
  bool _isLoading = true;

  // Filter state
  Set<String> _selectedDates = {};
  Set<String> _selectedTypes = {};
  Set<String> _selectedAudiences = {};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  @override
  void didUpdateWidget(AgendaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedYear != widget.selectedYear) {
      _loadSchedule();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedule({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final sessions = await _scheduleService.fetchSchedule(
        forceRefresh: forceRefresh,
        year: widget.selectedYear,
      );

      if (!mounted) return;
      setState(() {
        _allSessions = sessions;
        _filteredSessions = sessions;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading schedule: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }


  void _applyFilters() {
    setState(() {
      _filteredSessions = _allSessions.where((session) {
        final dateMatch = _selectedDates.isEmpty || _selectedDates.contains(session.dateKey);
        final typeMatch = _selectedTypes.isEmpty || _selectedTypes.contains(session.type);
        final audienceMatch = _selectedAudiences.isEmpty || _selectedAudiences.contains(session.audience);
        
        // Search filter
        final searchMatch = _searchQuery.isEmpty || 
            session.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            session.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            session.speaker.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            session.location.toLowerCase().contains(_searchQuery.toLowerCase());
        
        return dateMatch && typeMatch && audienceMatch && searchMatch;
      }).toList();
    });
  }

  void _showFilterSheet() {
    // Get unique values
    final dates = _allSessions.map((s) => s.dateKey).toSet().toList()..sort();
    final types = _allSessions.map((s) => s.type).toSet().toList()..sort();
    final audiences = _allSessions.map((s) => s.audience).toSet().toList()..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FilterBottomSheet(
        availableDates: dates,
        availableTypes: types,
        availableAudiences: audiences,
        selectedDates: _selectedDates,
        selectedTypes: _selectedTypes,
        selectedAudiences: _selectedAudiences,
        onApply: (dates, types, audiences) {
          setState(() {
            _selectedDates = dates;
            _selectedTypes = types;
            _selectedAudiences = audiences;
          });
          _applyFilters();
        },
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedDates.clear();
      _selectedTypes.clear();
      _selectedAudiences.clear();
      _searchQuery = '';
      _searchController.clear();
    });
    _applyFilters();
  }

  bool get _hasActiveFilters =>
      _selectedDates.isNotEmpty || _selectedTypes.isNotEmpty || _selectedAudiences.isNotEmpty || _searchQuery.isNotEmpty;

  Map<String, List<Session>> _groupSessionsByDate() {
    final Map<String, List<Session>> grouped = {};
    for (var session in _filteredSessions) {
      grouped.putIfAbsent(session.dateKey, () => []).add(session);
    }
    // Sort sessions within each date by start time
    for (var sessions in grouped.values) {
      sessions.sort((a, b) => a.startTime.compareTo(b.startTime));
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedSessions = _groupSessionsByDate();
    final sortedDates = groupedSessions.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'REDCap Con',
              style: TextStyle(fontSize: 17),
            ),
            const SizedBox(width: 6),
            DropdownButton<int>(
              value: widget.selectedYear,
              underline: Container(),
              dropdownColor: Theme.of(context).colorScheme.primary,
              iconEnabledColor: Theme.of(context).colorScheme.onPrimary,
              isDense: true,
              selectedItemBuilder: (BuildContext context) {
                // Show just year with star in app bar (compact)
                return [2026, 2025, 2024, 2023, 2022].map((int year) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$year',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (year == 2026) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.star,
                          size: 12,
                          color: Color(0xFFFFD700),
                        ),
                      ],
                    ],
                  );
                }).toList();
              },
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              items: [
                DropdownMenuItem(
                  value: 2026,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('2026', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.star,
                                size: 12,
                                color: Color(0xFFFFD700),
                              ),
                            ],
                          ),
                          Text('Oklahoma City, OK', style: TextStyle(fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 2025,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('2025', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Stevens Point, WI', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 2024,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('2024', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('St. Petersburg, FL', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 2023,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('2023', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Seattle, WA', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 2022,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('2022', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Boston, MA', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ],
              onChanged: (year) {
                if (year != null && year != widget.selectedYear) {
                  widget.onYearChanged?.call(year);
                  setState(() {
                    _selectedDates.clear();
                    _selectedTypes.clear();
                    _selectedAudiences.clear();
                  });
                  _loadSchedule();
                }
              },
            ),
          ],
        ),
        actions: [
          if (_hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.filter_list_off),
              onPressed: _clearFilters,
              tooltip: 'Clear filters',
            ),
          IconButton(
            icon: Badge(
              isLabelVisible: _hasActiveFilters,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _showFilterSheet,
            tooltip: 'Filter',
          ),
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          // Historical year indicator banner
          if (widget.selectedYear != 2026)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.25),
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Viewing ${widget.selectedYear} Schedule (Historical)',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      widget.onYearChanged?.call(2026);
                      setState(() {
                        _selectedDates.clear();
                        _selectedTypes.clear();
                        _selectedAudiences.clear();
                      });
                      _loadSchedule();
                    },
                    icon: Icon(Icons.today, size: 16),
                    label: const Text('2026'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                      foregroundColor: Theme.of(context).colorScheme.onTertiary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                ],
              ),
            ),
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search sessions, speakers, locations...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _applyFilters();
              },
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 64,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No sessions found',
                        style: TextStyle(fontSize: 18),
                      ),
                      if (_hasActiveFilters) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Clear filters'),
                        ),
                      ],
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
                          ...sessions.map((session) => SessionCard(
                                showBookmark: widget.selectedYear == 2026,
                                session: session,
                                onTap: () => _showSessionDetails(session),
                              )),
                        ],
                      );
                    },
                  ),
          ),
        ],
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
                  if (widget.selectedYear == 2026) ...[
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
