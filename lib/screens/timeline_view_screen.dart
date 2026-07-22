import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/session.dart';
import '../services/schedule_service.dart';
import '../services/badge_service.dart';

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

  // ── Layout constants ─────────────────────────────────────────────────────
  static const double _timeColWidth = 64.0;
  static const double _headerHeight = 50.0;
  static const double _cellWidth    = 200.0;
  static const double _cellPad      = 4.0;
  static const double _sessionCardH = 76.0; // height per session card in a slot
  static const double _rowMinH      = 56.0;

  // ── Scroll controllers ───────────────────────────────────────────────────
  // _dataH / _dataV drive the main grid; the sticky header and time column
  // are slaved to them via jumpTo() and NeverScrollableScrollPhysics.
  final ScrollController _dataH = ScrollController();
  final ScrollController _dataV = ScrollController();
  final ScrollController _headH = ScrollController();
  final ScrollController _timeV = ScrollController();

  @override
  void initState() {
    super.initState();
    _dataH.addListener(_syncH);
    _dataV.addListener(_syncV);
    BadgeService().trackYearBrowse(widget.selectedYear);
    _loadSchedule();
  }

  @override
  void dispose() {
    _dataH.removeListener(_syncH);
    _dataV.removeListener(_syncV);
    _dataH.dispose();
    _dataV.dispose();
    _headH.dispose();
    _timeV.dispose();
    super.dispose();
  }

  void _syncH() {
    if (_headH.hasClients && _headH.offset != _dataH.offset) {
      _headH.jumpTo(_dataH.offset);
    }
  }

  void _syncV() {
    if (_timeV.hasClients && _timeV.offset != _dataV.offset) {
      _timeV.jumpTo(_dataV.offset);
    }
  }

  @override
  void didUpdateWidget(TimelineViewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedYear != widget.selectedYear) {
      BadgeService().trackYearBrowse(widget.selectedYear);
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

  // ── Data helpers ─────────────────────────────────────────────────────────

  Map<String, Map<String, List<Session>>> _groupByTimeSlots() {
    final sessionsByDate = <String, List<Session>>{};
    for (var session in _allSessions) {
      sessionsByDate.putIfAbsent(session.dateKey, () => []).add(session);
    }
    for (var sessions in sessionsByDate.values) {
      sessions.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    final timeSlots = <String, Map<String, List<Session>>>{};
    for (var date in sessionsByDate.keys) {
      for (var session in sessionsByDate[date]!) {
        final h = session.startTime.toUtc().hour;
        final m = session.startTime.toUtc().minute;
        final key = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
        timeSlots.putIfAbsent(key, () => {});
        timeSlots[key]!.putIfAbsent(date, () => []).add(session);
      }
    }
    return timeSlots;
  }

  List<String> _getSortedTimeSlots(Map<String, Map<String, List<Session>>> timeSlots) {
    final slots = timeSlots.keys.toList();
    slots.sort((a, b) {
      final ah = int.parse(a.split(':')[0]), am = int.parse(a.split(':')[1]);
      final bh = int.parse(b.split(':')[0]), bm = int.parse(b.split(':')[1]);
      return ah != bh ? ah.compareTo(bh) : am.compareTo(bm);
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
      return DateFormat('EEE\nMMM d').format(DateTime.parse(dateKey));
    } catch (_) {
      return dateKey;
    }
  }

  String _formatTimeSlot(String slot) {
    try {
      final h = int.parse(slot.split(':')[0]);
      final m = int.parse(slot.split(':')[1]);
      final dt = DateTime(2000, 1, 1, h, m);
      return DateFormat('h:mm\na').format(dt);
    } catch (_) {
      return slot;
    }
  }

  Map<String, double> _computeRowHeights(
    List<String> sortedSlots,
    Map<String, Map<String, List<Session>>> timeSlots,
  ) {
    return {
      for (var slot in sortedSlots)
        slot: max(
          _rowMinH,
          timeSlots[slot]!.values
                  .map((l) => l.length)
                  .fold(0, max)
                  .toDouble() *
              _sessionCardH,
        ),
    };
  }

  // ── Session detail sheet ─────────────────────────────────────────────────

  void _showSessionDetails(Session session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, sc) => SingleChildScrollView(
          controller: sc,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(session.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                const SizedBox(height: 12),
                _detailRow(Icons.access_time, session.timeRange),
                _detailRow(Icons.location_on, session.location),
                if (session.speaker.isNotEmpty)
                  _detailRow(Icons.person, session.speaker),
                _detailRow(Icons.category, session.type),
                _detailRow(Icons.people, session.audience),
                const SizedBox(height: 16),
                if (session.description.isNotEmpty) ...[
                  Text('Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                  const SizedBox(height: 8),
                  Text(session.description,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FutureBuilder<bool>(
                    future: _scheduleService.isSessionSaved(session.id),
                    builder: (context, snap) {
                      final isSaved = snap.data ?? false;
                      return FilledButton.icon(
                        onPressed: () async {
                          await _scheduleService.toggleSession(session.id,
                              session: session);
                          setState(() {});
                          if (context.mounted) Navigator.pop(context);
                        },
                        icon: Icon(
                            isSaved ? Icons.bookmark_remove : Icons.bookmark_add),
                        label: Text(isSaved
                            ? 'Remove from My Schedule'
                            : 'Add to My Schedule'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ]),
      );

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Timeline View - ${widget.selectedYear}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final timeSlots   = _groupByTimeSlots();
    final sortedSlots = _getSortedTimeSlots(timeSlots);
    final sortedDates = _getSortedDates();
    final rowHeights  = _computeRowHeights(sortedSlots, timeSlots);
    final cs          = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Timeline View - ${widget.selectedYear}')),
      body: Column(
        children: [
          _buildHeader(sortedDates, cs),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimeColumn(sortedSlots, rowHeights, cs),
                Expanded(
                  child: _buildGrid(sortedSlots, sortedDates, timeSlots, rowHeights, cs),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Sticky header (date row) ──────────────────────────────────────────────

  Widget _buildHeader(List<String> sortedDates, ColorScheme cs) {
    return Container(
      height: _headerHeight,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant, width: 1)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.10),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Corner — always visible
          _buildCorner(cs),
          // Vertical rule between corner and scrollable header
          Container(width: 1, height: _headerHeight, color: cs.outlineVariant),
          // Date headers — driven by _headH (synced from _dataH)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _headH,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: sortedDates.map((date) => _buildDateCell(date, cs)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(ColorScheme cs) {
    return Container(
      width: _timeColWidth,
      height: _headerHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primaryContainer,
            cs.primaryContainer.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Center(
        child: Text(
          'CDT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: cs.onPrimaryContainer,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildDateCell(String date, ColorScheme cs) {
    return SizedBox(
      width: _cellWidth,
      height: _headerHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _cellPad, vertical: 6),
        child: Container(
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              _formatDate(date),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: cs.onPrimaryContainer,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  // ── Sticky time column ────────────────────────────────────────────────────

  Widget _buildTimeColumn(
    List<String> sortedSlots,
    Map<String, double> rowHeights,
    ColorScheme cs,
  ) {
    return Container(
      width: _timeColWidth,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(right: BorderSide(color: cs.outlineVariant, width: 1)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.10),
            blurRadius: 6,
            offset: const Offset(3, 0),
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: _timeV,
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: sortedSlots.map((slot) {
            return Container(
              width: _timeColWidth,
              height: rowHeights[slot]!,
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.4),
                    width: 0.5,
                  ),
                ),
              ),
              child: Text(
                _formatTimeSlot(slot),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Scrollable data grid ──────────────────────────────────────────────────

  Widget _buildGrid(
    List<String> sortedSlots,
    List<String> sortedDates,
    Map<String, Map<String, List<Session>>> timeSlots,
    Map<String, double> rowHeights,
    ColorScheme cs,
  ) {
    return SingleChildScrollView(
      controller: _dataV,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _dataH,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sortedSlots.map((slot) {
            final sessionsInSlot = timeSlots[slot]!;
            return SizedBox(
              height: rowHeights[slot]!,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sortedDates.map((date) {
                  final sessions = sessionsInSlot[date] ?? [];
                  return SizedBox(
                    width: _cellWidth,
                    child: Padding(
                      padding: const EdgeInsets.all(_cellPad),
                      child: sessions.isEmpty
                          ? _buildEmptyCell(cs)
                          : Column(
                              children: sessions
                                  .map((s) => _buildSessionCard(s, cs))
                                  .toList(),
                            ),
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyCell(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
    );
  }

  Widget _buildSessionCard(Session session, ColorScheme cs) {
    return FutureBuilder<bool>(
      future: _scheduleService.isSessionSaved(session.id),
      builder: (context, snap) {
        final isSaved = snap.data ?? false;
        final bg = isSaved ? cs.primaryContainer : cs.secondaryContainer;
        final fg = isSaved ? cs.onPrimaryContainer : cs.onSecondaryContainer;
        return GestureDetector(
          onTap: () => _showSessionDetails(session),
          child: Container(
            height: _sessionCardH - 8,
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSaved
                    ? cs.primary.withValues(alpha: 0.55)
                    : cs.outlineVariant.withValues(alpha: 0.3),
                width: isSaved ? 1.5 : 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isSaved) ...[
                      Icon(Icons.bookmark, size: 11, color: cs.primary),
                      const SizedBox(width: 3),
                    ],
                    Expanded(
                      child: Text(
                        session.title,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: fg,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (session.location.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 9,
                          color: fg.withValues(alpha: 0.6)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          session.location,
                          style: TextStyle(
                            fontSize: 9,
                            color: fg.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
