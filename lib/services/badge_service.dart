import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/badge_model.dart';

class BadgeService {
  static final BadgeService _instance = BadgeService._internal();
  factory BadgeService() => _instance;
  BadgeService._internal();

  static const String _earnedBadgesKey    = 'earned_badges';
  static const String _visitedTabsKey     = 'visited_tabs';
  static const String _browsedYearsKey    = 'browsed_years';
  static const String _totalMinutesKey    = 'total_app_minutes';
  static const String _savedTypesKey      = 'saved_session_types';
  static const String _saveTimestampsKey      = 'save_timestamps';
  static const String _sessionTogglePrefix    = 'session_toggles_';
  static const String _savedKeynotePlenaryKey = 'saved_keynote_plenary_ids';

  /// SharedPreferences key prefix for per-badge earned year:
  ///   `earned_year_<id>`  →  int (e.g. 2026)
  static const String _earnedYearPrefix = 'earned_year_';

  final _awardController = StreamController<AppBadge>.broadcast();
  Stream<AppBadge> get onBadgeAwarded => _awardController.stream;

  // ── Series colours ────────────────────────────────────────────────────────

  static const Color _scheduleColor      = Color(0xFF3B82F6);
  static const Color _scheduleColorDark  = Color(0xFF1D4ED8);
  static const Color _explorerColor      = Color(0xFF8B5CF6);
  static const Color _explorerColorDark  = Color(0xFF6D28D9);
  static const Color _dedicatedColor     = Color(0xFFF59E0B);
  static const Color _dedicatedColorDark = Color(0xFFD97706);
  static const Color _mysteryColor       = Color(0xFFBE185D);
  static const Color _mysteryColorDark   = Color(0xFF9D174D);

  // ── Points ────────────────────────────────────────────────────────────────
  //
  // Individual badge pts: SB 1+2+3+4=10, CE 3+4+3+4=14, DA 3+3+4+5=15, M 7+7+9+17=40
  // Series bonuses:       SB +3, CE +4, DA +4  (Mystery has no series bonus)
  // Any-3-series bonus:   +10 (once any 3 of 4 series are fully complete)
  // Non-mystery subtotal: 13 + 18 + 19 + 10 = 60 pts
  // Mystery subtotal:     40 pts
  // Maximum total:        100 pts

  static const Map<String, int> seriesBonuses = {
    'Schedule Builder':    3,
    'Conference Explorer': 4,
    'Dedicated Attendee':  4,
    'Mystery':             0,
  };
  static const int anyThreeSeriesBonus = 10;
  static const int maxPoints = 100;

  // ── Badge definitions ────────────────────────────────────────────────────

  static const List<AppBadge> allBadges = [
    // ── Series 1: Schedule Builder ────────────────────────────────────────
    AppBadge(
      id: 'first_pick',
      name: 'Five Pick',
      description: 'Five sessions locked in — your conference is taking shape!',
      howToEarn: 'Save 5 sessions to My Schedule.',
      emoji: '🎯',
      series: 'Schedule Builder',
      seriesColor: _scheduleColor,
      seriesColorDark: _scheduleColorDark,
      points: 1,
    ),
    AppBadge(
      id: 'on_a_roll',
      name: 'On a Roll',
      description: '15 sessions saved — you\'re on a mission!',
      howToEarn: 'Save 15 sessions to My Schedule.',
      emoji: '🎲',
      series: 'Schedule Builder',
      seriesColor: _scheduleColor,
      seriesColorDark: _scheduleColorDark,
      points: 2,
    ),
    AppBadge(
      id: 'power_planner',
      name: 'Power Planner',
      description: '25 sessions — you clearly mean business.',
      howToEarn: 'Save 25 sessions to My Schedule.',
      emoji: '⚡',
      series: 'Schedule Builder',
      seriesColor: _scheduleColor,
      seriesColorDark: _scheduleColorDark,
      points: 3,
    ),
    AppBadge(
      id: 'schedule_legend',
      name: 'Schedule Legend',
      description: '40 sessions saved — practically a conference legend.',
      howToEarn: 'Save 40 sessions to My Schedule.',
      emoji: '🏆',
      series: 'Schedule Builder',
      seriesColor: _scheduleColor,
      seriesColorDark: _scheduleColorDark,
      points: 4,
    ),

    // ── Series 2: Conference Explorer ─────────────────────────────────────
    AppBadge(
      id: 'tab_tourist',
      name: 'Tab Tourist',
      description: 'You explored every corner of the app!',
      howToEarn: 'Visit all 5 tabs: Agenda, Timeline, Search, Badges, My Schedule.',
      emoji: '🗺️',
      series: 'Conference Explorer',
      seriesColor: _explorerColor,
      seriesColorDark: _explorerColorDark,
      points: 3,
    ),
    AppBadge(
      id: 'history_buff',
      name: 'History Buff',
      description: 'A true REDCap historian — all years explored.',
      howToEarn: 'Browse all 5 conference years (2022 – 2026) via the year selector.',
      emoji: '📚',
      series: 'Conference Explorer',
      seriesColor: _explorerColor,
      seriesColorDark: _explorerColorDark,
      points: 4,
    ),
    AppBadge(
      id: 'genre_sampler',
      name: 'Genre Sampler',
      description: 'Workshops, plenaries, discussions — you tried it all.',
      howToEarn: 'Save sessions from 5 or more different session types.',
      emoji: '🎨',
      series: 'Conference Explorer',
      seriesColor: _explorerColor,
      seriesColorDark: _explorerColorDark,
      points: 3,
    ),
    AppBadge(
      id: 'vip_access',
      name: 'VIP Access',
      description: 'Every keynote and plenary saved — true front-row royalty.',
      howToEarn: 'Save 15 or more Keynote or Plenary sessions.',
      emoji: '👑',
      series: 'Conference Explorer',
      seriesColor: _explorerColor,
      seriesColorDark: _explorerColorDark,
      points: 4,
    ),

    // ── Series 3: Dedicated Attendee ──────────────────────────────────────
    AppBadge(
      id: 'early_bird',
      name: 'Early Bird',
      description: 'Morning person confirmed — app open before 8 AM!',
      howToEarn: 'Open the app before 8:00 AM.',
      emoji: '🐦',
      series: 'Dedicated Attendee',
      seriesColor: _dedicatedColor,
      seriesColorDark: _dedicatedColorDark,
      points: 3,
    ),
    AppBadge(
      id: 'night_owl',
      name: 'Night Owl',
      description: 'Burning the midnight oil — app open after 10 PM.',
      howToEarn: 'Open the app after 10:00 PM.',
      emoji: '🦉',
      series: 'Dedicated Attendee',
      seriesColor: _dedicatedColor,
      seriesColorDark: _dedicatedColorDark,
      points: 3,
    ),
    AppBadge(
      id: 'half_hour_hero',
      name: 'Half Hour Hero',
      description: '30 minutes in — conference mode fully activated!',
      howToEarn: 'Keep the app in the foreground for a total of 30 minutes.',
      emoji: '⏱️',
      series: 'Dedicated Attendee',
      seriesColor: _dedicatedColor,
      seriesColorDark: _dedicatedColorDark,
      points: 4,
    ),
    AppBadge(
      id: 'marathon_mode',
      name: 'Marathon Mode',
      description: '2 hours on the app — you might actually live here now.',
      howToEarn: 'Keep the app in the foreground for a total of 2 hours.',
      emoji: '🏃',
      series: 'Dedicated Attendee',
      seriesColor: _dedicatedColor,
      seriesColorDark: _dedicatedColorDark,
      points: 5,
    ),

    // ── Series 4: Mystery ─────────────────────────────────────────────────
    AppBadge(
      id: 'phantom',
      name: 'Phantom',
      description: 'A ghost in the machine — caught using the app at midnight!',
      howToEarn: 'Open the app between midnight and 1:00 AM.',
      emoji: '👻',
      series: 'Mystery',
      seriesColor: _mysteryColor,
      seriesColorDark: _mysteryColorDark,
      points: 7,
    ),
    AppBadge(
      id: 'flip_flopper',
      name: 'Flip Flopper',
      description: 'Added it. Removed it. Five times over — indecision is an art.',
      howToEarn: 'Add and remove the same session 5 times.',
      emoji: '🔀',
      series: 'Mystery',
      seriesColor: _mysteryColor,
      seriesColorDark: _mysteryColorDark,
      points: 7,
    ),
    AppBadge(
      id: 'blitz',
      name: 'Blitz',
      description: 'Seven sessions in under 3 minutes — are you even reading the titles?',
      howToEarn: 'Save 7 different sessions within 3 minutes.',
      emoji: '💨',
      series: 'Mystery',
      seriesColor: _mysteryColor,
      seriesColorDark: _mysteryColorDark,
      points: 9,
    ),
    AppBadge(
      id: 'continental',
      name: 'Continental',
      description: 'Bon appétit! You found a secret first course — a taste of REDCapCon 2022.',
      howToEarn: 'Somewhere in the 2022 schedule lies a hidden treasure. Find it.',
      emoji: '🥐',
      series: 'Mystery',
      seriesColor: _mysteryColor,
      seriesColorDark: _mysteryColorDark,
      points: 17,
    ),
  ];

  // ── Points calculation ────────────────────────────────────────────────────

  static int computeTotalPoints(Set<String> earnedIds) {
    int total = 0;
    // Individual badge points
    for (final badge in allBadges) {
      if (earnedIds.contains(badge.id)) {
        total += badge.points;
      }
    }
    // Series bonuses
    final bySeriesMap = badgesBySeries;
    int completedSeriesCount = 0;
    for (final entry in bySeriesMap.entries) {
      if (entry.value.every((b) => earnedIds.contains(b.id))) {
        total += seriesBonuses[entry.key] ?? 0;
        completedSeriesCount++;
      }
    }
    // Any-3-series bonus
    if (completedSeriesCount >= 3) {
      total += anyThreeSeriesBonus;
    }
    return total;
  }

  // ── Query ────────────────────────────────────────────────────────────────

  Future<Set<String>> getEarnedBadgeIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_earnedBadgesKey)?.toSet() ?? {};
  }

  /// Returns a map of badgeId → year it was earned (e.g. {'first_pick': 2026}).
  Future<Map<String, int>> getEarnedBadgeYears() async {
    final prefs = await SharedPreferences.getInstance();
    final earned = prefs.getStringList(_earnedBadgesKey)?.toSet() ?? {};
    final result = <String, int>{};
    for (final id in earned) {
      final year = prefs.getInt('$_earnedYearPrefix$id');
      if (year != null) result[id] = year;
    }
    return result;
  }

  // ── Award ────────────────────────────────────────────────────────────────

  Future<bool> _award(String badgeId) async {
    final prefs = await SharedPreferences.getInstance();
    final earned = prefs.getStringList(_earnedBadgesKey)?.toSet() ?? {};
    if (earned.contains(badgeId)) return false;
    earned.add(badgeId);
    await prefs.setStringList(_earnedBadgesKey, earned.toList());
    // Persist the year it was earned so future screens can show "Earned '26"
    await prefs.setInt('$_earnedYearPrefix$badgeId', DateTime.now().year);
    final badge = allBadges.firstWhere((b) => b.id == badgeId);
    _awardController.add(badge);
    return true;
  }

  // ── Schedule Builder checks ──────────────────────────────────────────────

  Future<void> onSessionAdded({
    required String sessionId,
    required String sessionType,
    required int savedCount,
  }) async {
    if (savedCount >= 5)  await _award('first_pick');
    if (savedCount >= 15) await _award('on_a_roll');
    if (savedCount >= 25) await _award('power_planner');
    if (savedCount >= 40) await _award('schedule_legend');

    final t = sessionType.toLowerCase();
    final prefs = await SharedPreferences.getInstance();

    if (t == 'keynote' || t == 'plenary') {
      final saved = prefs.getStringList(_savedKeynotePlenaryKey)?.toSet() ?? {};
      saved.add(sessionId);
      await prefs.setStringList(_savedKeynotePlenaryKey, saved.toList());
      if (saved.length >= 15) await _award('vip_access');
    }

    final types = prefs.getStringList(_savedTypesKey)?.toSet() ?? {};
    types.add(t);
    await prefs.setStringList(_savedTypesKey, types.toList());
    if (types.length >= 5) await _award('genre_sampler');
  }

  // ── Conference Explorer checks ───────────────────────────────────────────

  Future<void> trackTabVisit(int tabIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final visited = prefs.getStringList(_visitedTabsKey)?.toSet() ?? {};
    visited.add(tabIndex.toString());
    await prefs.setStringList(_visitedTabsKey, visited.toList());
    if (visited.length >= 5) await _award('tab_tourist');
  }

  Future<void> trackYearBrowse(int year) async {
    final prefs = await SharedPreferences.getInstance();
    final browsed = prefs.getStringList(_browsedYearsKey)?.toSet() ?? {};
    browsed.add(year.toString());
    await prefs.setStringList(_browsedYearsKey, browsed.toList());
    if ({'2022', '2023', '2024', '2025', '2026'}.every(browsed.contains)) {
      await _award('history_buff');
    }
  }

  // ── Dedicated Attendee checks ────────────────────────────────────────────

  Future<void> checkTimeOfDayBadges() async {
    final hour = DateTime.now().hour;
    if (hour < 8)   await _award('early_bird');
    if (hour >= 22) await _award('night_owl');
    if (hour == 0)  await _award('phantom'); // midnight mystery badge
  }

  Future<void> addAppMinutes(int minutes) async {
    if (minutes <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final total = (prefs.getInt(_totalMinutesKey) ?? 0) + minutes;
    await prefs.setInt(_totalMinutesKey, total);
    if (total >= 30)  await _award('half_hour_hero');
    if (total >= 120) await _award('marathon_mode');
  }

  Future<int> getTotalAppMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalMinutesKey) ?? 0;
  }

  // ── Mystery checks ───────────────────────────────────────────────────────

  /// Call on BOTH add and remove of a session to track flip_flopper.
  Future<void> trackSessionToggle(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_sessionTogglePrefix$sessionId';
    final count = (prefs.getInt(key) ?? 0) + 1;
    await prefs.setInt(key, count);
    // 10 toggles = 5 adds + 5 removes on the same session
    if (count >= 10) await _award('flip_flopper');
  }

  /// Call when a session is saved to track blitz (5 saves within 3 minutes).
  Future<void> trackSaveTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_saveTimestampsKey) ?? [];
    final now = DateTime.now();
    raw.add(now.toIso8601String());
    // Keep only the last 20 timestamps to avoid unbounded growth
    final trimmed = raw.length > 20 ? raw.sublist(raw.length - 20) : raw;
    await prefs.setStringList(_saveTimestampsKey, trimmed);

    final cutoff = now.subtract(const Duration(minutes: 3));
    final recentCount = trimmed
        .map((s) => DateTime.tryParse(s))
        .whereType<DateTime>()
        .where((dt) => dt.isAfter(cutoff))
        .length;
    if (recentCount >= 7) await _award('blitz');
  }

  /// Call when a session is tapped to check for the Continental treasure-hunt badge.
  /// Target: session id '2022-8' (Breakfast, REDCapCon 2022, Grand B Foyer).
  Future<void> checkTreasureHuntSession(String sessionId) async {
    if (sessionId == '2022-8') await _award('continental');
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static Map<String, List<AppBadge>> get badgesBySeries {
    final map = <String, List<AppBadge>>{};
    for (final b in allBadges) {
      map.putIfAbsent(b.series, () => []).add(b);
    }
    return map;
  }

  static Color seriesColor(String series) {
    switch (series) {
      case 'Schedule Builder':    return _scheduleColor;
      case 'Conference Explorer': return _explorerColor;
      case 'Dedicated Attendee':  return _dedicatedColor;
      case 'Mystery':             return _mysteryColor;
      default:                    return Colors.grey;
    }
  }
}
