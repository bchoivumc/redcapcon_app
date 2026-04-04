import 'package:flutter/material.dart';
import '../models/session.dart';
import '../services/schedule_service.dart';
import '../widgets/session_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ScheduleService _scheduleService = ScheduleService();
  final TextEditingController _searchController = TextEditingController();
  
  Map<int, List<Session>> _allSessionsByYear = {};
  List<Session> _searchResults = [];
  Set<int> _selectedYears = {2022, 2023, 2024, 2025, 2026};
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllYears();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllYears() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final years = [2022, 2023, 2024, 2025, 2026];
    for (final year in years) {
      final sessions = await _scheduleService.fetchSchedule(year: year);
      _allSessionsByYear[year] = sessions;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    _performSearch();
  }

  void _performSearch() {
    if (_searchQuery.isEmpty) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }

    final results = <Session>[];
    for (final year in _selectedYears) {
      final sessions = _allSessionsByYear[year] ?? [];
      final filtered = sessions.where((session) {
        final query = _searchQuery.toLowerCase();
        return session.title.toLowerCase().contains(query) ||
            session.description.toLowerCase().contains(query) ||
            session.speaker.toLowerCase().contains(query) ||
            session.location.toLowerCase().contains(query) ||
            session.type.toLowerCase().contains(query) ||
            session.audience.toLowerCase().contains(query);
      }).toList();
      results.addAll(filtered);
    }

    // Sort by start time, most recent first
    results.sort((a, b) => b.startTime.compareTo(a.startTime));

    if (mounted) setState(() => _searchResults = results);
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
          // Determine year from session start time
          final year = session.startTime.year;
          final showBookmark = year == 2026;

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
                  // Year badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'REDCap Con $year',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  if (showBookmark) ...[
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search All Years'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search sessions across all years...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                          _performSearch();
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
                _performSearch();
              },
            ),
          ),
          // Year filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Wrap(
              spacing: 8,
              children: [2026, 2025, 2024, 2023, 2022].map((year) {
                final isSelected = _selectedYears.contains(year);
                return FilterChip(
                  label: Text(year.toString()),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedYears.add(year);
                      } else {
                        _selectedYears.remove(year);
                      }
                    });
                    _performSearch();
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchQuery.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 64,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Search across all conference years',
                              style: TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      )
                    : _searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No sessions found',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final session = _searchResults[index];
                              final year = session.startTime.year;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (index == 0 ||
                                      _searchResults[index - 1].startTime.year != year)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                      child: Text(
                                        'REDCap Con $year',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                      ),
                                    ),
                                  SessionCard(
                                    session: session,
                                    showBookmark: year == 2026,
                                    onTap: () => _showSessionDetails(session),
                                  ),
                                ],
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
