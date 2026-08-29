import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../services/schedule_service.dart';
import '../services/badge_service.dart';
import '../widgets/session_card.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../theme/time_format_provider.dart';
import '../theme/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _searchFieldVisible = false;

  // Filter state
  Set<String> _selectedDates = {};
  Set<String> _selectedTypes = {};
  Set<String> _selectedAudiences = {};
  final Set<String> _collapsedDates = {};
  final Map<String, GlobalKey> _dateKeys = {};
  String _wildcardLabel = '';
  String _wildcardUrl = '';
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listKey = GlobalKey();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    BadgeService().trackYearBrowse(widget.selectedYear);
    _loadSchedule();
    _loadWildcard();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _searchFieldVisible = true);
    });
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
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedule({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

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

      // After showing cached data, silently check for updates in background
      if (widget.selectedYear == 2026 && !forceRefresh) {
        _backgroundRefresh();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
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

  Future<void> _backgroundRefresh() async {
    try {
      final fresh = await _scheduleService.fetchSchedule(
        forceRefresh: true,
        year: 2026,
      );
      if (!mounted) return;
      if (fresh.length != _allSessions.length) {
        setState(() => _allSessions = fresh);
        _applyFilters();
      }
    } catch (_) {
      // Silently ignore — background refresh, don't surface errors to user
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

  Future<void> _loadWildcard() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _wildcardLabel = prefs.getString('quicklink_label') ?? '';
      _wildcardUrl = prefs.getString('quicklink_url') ?? '';
    });
  }

  Future<void> _saveWildcard(String label, String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quicklink_label', label);
    await prefs.setString('quicklink_url', url);
  }

  Future<void> _launchUrl(String rawUrl) async {
    final uri = Uri.parse(rawUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not open link')));
      }
    }
  }

  void _showQuickLinks() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        String wcLabel = _wildcardLabel;
        String wcUrl = _wildcardUrl;

        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 36, height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Quick Links',
                          style: Theme.of(sheetCtx).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.dashboard_outlined),
                      title: const Text('Con Dashboard'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _launchUrl('https://redcap.vumc.org/surveys/?__dashboard=7YEYW7CYA7F');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.photo_library_outlined),
                      title: const Text('Conference Photos'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _launchUrl('https://photos.app.goo.gl/qBe11ybrr2ddCFWAA');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.upload_outlined),
                      title: const Text('Upload (share) photo'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _launchUrl('https://redcap.vumc.org/surveys/?s=CLATFYY7CK4C7NA8');
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        wcUrl.isEmpty ? Icons.add_link : Icons.link,
                        color: wcUrl.isEmpty
                            ? Theme.of(sheetCtx).colorScheme.secondary
                            : null,
                      ),
                      title: Text(
                        wcLabel.isEmpty ? 'Add custom link…' : wcLabel,
                        style: wcUrl.isEmpty
                            ? TextStyle(
                                color: Theme.of(sheetCtx).colorScheme.secondary,
                                fontStyle: FontStyle.italic,
                              )
                            : null,
                      ),
                      subtitle: wcUrl.isEmpty
                          ? null
                          : Text(wcUrl,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        tooltip: 'Edit',
                        onPressed: () async {
                          final labelCtrl =
                              TextEditingController(text: wcLabel);
                          final urlCtrl =
                              TextEditingController(text: wcUrl);
                          final saved = await showDialog<bool>(
                            context: sheetCtx,
                            builder: (dlgCtx) => AlertDialog(
                              title: const Text('Custom Link'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: labelCtrl,
                                    decoration: const InputDecoration(
                                        labelText: 'Label',
                                        hintText: 'e.g. Slack channel'),
                                    textCapitalization:
                                        TextCapitalization.words,
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: urlCtrl,
                                    decoration: const InputDecoration(
                                        labelText: 'URL',
                                        hintText: 'https://…'),
                                    keyboardType: TextInputType.url,
                                    autocorrect: false,
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dlgCtx, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(dlgCtx, true),
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          );
                          if (saved == true) {
                            final newLabel = labelCtrl.text.trim();
                            var newUrl = urlCtrl.text.trim();
                            if (newUrl.isNotEmpty &&
                                !newUrl.startsWith('http://') &&
                                !newUrl.startsWith('https://')) {
                              newUrl = 'https://$newUrl';
                            }
                            await _saveWildcard(newLabel, newUrl);
                            setSheetState(() {
                              wcLabel = newLabel;
                              wcUrl = newUrl;
                            });
                            if (mounted) {
                              setState(() {
                                _wildcardLabel = newLabel;
                                _wildcardUrl = newUrl;
                              });
                            }
                          }
                          labelCtrl.dispose();
                          urlCtrl.dispose();
                        },
                      ),
                      onTap: wcUrl.isEmpty
                          ? null
                          : () {
                              Navigator.pop(sheetCtx);
                              _launchUrl(wcUrl);
                            },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterSheet() {
    // Get unique values
    final dates = _allSessions.map((s) => s.dateKey).toSet().toList()..sort();
    final types = _allSessions.map((s) => s.type).toSet().toList()..sort();
    final audiences = _allSessions.map((s) => s.audience).toSet().toList()..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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
                  BadgeService().trackYearBrowse(year);
                  setState(() {
                    _selectedDates.clear();
                    _selectedTypes.clear();
                    _selectedAudiences.clear();
                  });
                  // didUpdateWidget fires once widget.selectedYear is updated by
                  // the parent rebuild — calling _loadSchedule() here would use
                  // the old year and race against the correct load.
                }
              },
            ),
          ],
        ),
        actions: [
          if (context.watch<ThemeProvider>().currentTheme == 'golden')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Tooltip(
                message: 'VIP Access',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('👑', style: TextStyle(fontSize: 16)),
                    Text(
                      'VIP',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: Badge(
              isLabelVisible: _hasActiveFilters,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _showFilterSheet,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined),
            tooltip: 'Quick Links',
            onPressed: _showQuickLinks,
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
      body: _buildBody(context, sortedDates, groupedSessions),
    );
  }

  Widget _buildBody(BuildContext context, List<String> sortedDates, Map<String, List<Session>> groupedSessions) {
    return Column(
      children: [
        if (_hasActiveFilters)
          InkWell(
            onTap: _clearFilters,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Row(
                children: [
                  Icon(Icons.filter_list,
                      size: 13,
                      color: Theme.of(context).colorScheme.onSecondaryContainer),
                  const SizedBox(width: 6),
                  Text(
                    'Filters active',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Clear ×',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                Icon(Icons.history, color: Theme.of(context).colorScheme.onSurface, size: 20),
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
                  icon: const Icon(Icons.today, size: 16),
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
        if (_searchFieldVisible)
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _applyFilters();
              },
            ),
          ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredSessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 64, color: Theme.of(context).colorScheme.secondary),
                          const SizedBox(height: 16),
                          const Text('No sessions found', style: TextStyle(fontSize: 18)),
                          if (_hasActiveFilters) ...[
                            const SizedBox(height: 8),
                            TextButton(onPressed: _clearFilters, child: const Text('Clear filters')),
                          ],
                        ],
                      ),
                    )
                  : CustomScrollView(
                      key: _listKey,
                      controller: _scrollController,
                      slivers: [
                        for (final dateKey in sortedDates) ...[
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _DateHeaderDelegate(
                              dateText: DateFormat('EEEE, MMMM d, yyyy').format(
                                groupedSessions[dateKey]!.first.startTime.toUtc(),
                              ),
                              sessionCount: groupedSessions[dateKey]!.length,
                              isCollapsed: _collapsedDates.contains(dateKey),
                              onTap: () {
                                final wasCollapsed = _collapsedDates.contains(dateKey);
                                setState(() {
                                  if (wasCollapsed) {
                                    _collapsedDates.remove(dateKey);
                                  } else {
                                    _collapsedDates.add(dateKey);
                                  }
                                });
                                if (wasCollapsed) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    final key = _dateKeys[dateKey];
                                    if (key?.currentContext != null) {
                                      Scrollable.ensureVisible(
                                        key!.currentContext!,
                                        duration: const Duration(milliseconds: 350),
                                        curve: Curves.easeOut,
                                        alignment: 0.0,
                                        alignmentPolicy:
                                            ScrollPositionAlignmentPolicy.explicit,
                                      );
                                    }
                                  });
                                }
                              },
                              countTrailing: dateKey == sortedDates.first
                                  ? Builder(builder: (context) {
                                      final cs = Theme.of(context).colorScheme;
                                      return RichText(
                                        text: TextSpan(children: [
                                          TextSpan(
                                            text: '${groupedSessions[dateKey]!.length}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: cs.onPrimaryContainer,
                                            ),
                                          ),
                                          TextSpan(
                                            text: ' of ${_filteredSessions.length}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: cs.onPrimaryContainer.withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ]),
                                      );
                                    })
                                  : null,
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  key: _dateKeys.putIfAbsent(dateKey, GlobalKey.new),
                                  height: 0,
                                ),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeInOut,
                                  child: _collapsedDates.contains(dateKey)
                                      ? const SizedBox.shrink()
                                      : Column(
                                          children: groupedSessions[dateKey]!
                                              .map((session) => SessionCard(
                                                    showBookmark: widget.selectedYear == 2026,
                                                    session: session,
                                                    onTap: () => _showSessionDetails(session),
                                                  ))
                                              .toList(),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
        ),
      ],
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
          final use12h = Provider.of<TimeFormatProvider>(context, listen: false).use12h;
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
                  _buildDetailRow(Icons.access_time, session.formattedTimeRange(use12h)),
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

class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String dateText;
  final int sessionCount;
  final bool isCollapsed;
  final VoidCallback onTap;
  final Widget? countTrailing;

  const _DateHeaderDelegate({
    required this.dateText,
    required this.sessionCount,
    required this.isCollapsed,
    required this.onTap,
    this.countTrailing,
  });

  static const double _height = 48.0;

  @override double get minExtent => _height;
  @override double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.primaryContainer,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  dateText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              countTrailing ??
                  Text(
                    '$sessionCount',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: isCollapsed ? -0.25 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.expand_more,
                  color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_DateHeaderDelegate old) =>
      old.dateText != dateText ||
      old.sessionCount != sessionCount ||
      old.isCollapsed != isCollapsed;
}
