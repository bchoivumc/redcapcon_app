import 'package:flutter/material.dart';
import '../models/badge_model.dart';
import '../services/badge_service.dart';

// Tuple: (name, emoji, series, points, isNew)
// isNew = true  → new 2027 Nashville badge  (new emoji, ✨ chip shown)
// isNew = false → carried over from 2026    (familiar name/emoji, no chip)
const _nashvilleBadges = [
  // Schedule Builder — 2 new, 2 kept
  ('Setlist Starter',  '📋', 'Schedule Builder',    1,  true),
  ('Double Bill',      '🎟️', 'Schedule Builder',    2,  true),
  ('Power Planner',    '⚡', 'Schedule Builder',    3,  false),
  ('Schedule Legend',  '🏆', 'Schedule Builder',    4,  false),
  // Conference Explorer — 2 new, 2 kept
  ('Record Digger',    '💿', 'Conference Explorer', 3,  true),
  ("Songwriter's Eye", '🎻', 'Conference Explorer', 4,  true),
  ('Genre Sampler',    '🎨', 'Conference Explorer', 3,  false),
  ('VIP Access',       '👑', 'Conference Explorer', 4,  false),
  // Dedicated Attendee — 2 new, 2 kept
  ('Sound Check',      '🔊', 'Dedicated Attendee',  3,  true),
  ('Session Player',   '🎹', 'Dedicated Attendee',  5,  true),
  ('Night Owl',        '🦉', 'Dedicated Attendee',  4,  false),
  ('Marathon Mode',    '🏃', 'Dedicated Attendee',  8,  false),
  // Mystery — 2 new, 2 kept
  ('Boot Scooter',     '👢', 'Mystery',             5,  true),
  ('Steel Nerve',      '💎', 'Mystery',             5,  true),
  ('Phantom',          '👻', 'Mystery',             5,  false),
  ('Continental',      '🥐', 'Mystery',            10,  false),
];

/// Debug-only sneak peek of the proposed multi-year badge screen layout.
class Badges2027PreviewScreen extends StatefulWidget {
  const Badges2027PreviewScreen({super.key});

  @override
  State<Badges2027PreviewScreen> createState() =>
      _Badges2027PreviewScreenState();
}

class _Badges2027PreviewScreenState extends State<Badges2027PreviewScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Set<String> _earnedIds = {};
  Map<String, int> _earnedYears = {};
  bool _isLoading = true;

  bool get _hasAll2026 =>
      _earnedIds.length >= BadgeService.allBadges.length &&
      BadgeService.allBadges.every((b) => _earnedIds.contains(b.id));

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final ids = await BadgeService().getEarnedBadgeIds();
    final years = await BadgeService().getEarnedBadgeYears();
    if (mounted) {
      setState(() {
        _earnedIds = ids;
        _earnedYears = years;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Badge Screen Preview'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade400, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bug_report, size: 14, color: Colors.orange.shade700),
                const SizedBox(width: 4),
                Text(
                  'DEBUG PREVIEW',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '2027'),
            Tab(text: '2026'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _build2027Tab(context, cs),
                _build2026Tab(context, cs),
              ],
            ),
    );
  }

  // ── 2027 tab ─────────────────────────────────────────────────────────────

  Widget _build2027Tab(BuildContext context, ColorScheme cs) {
    // Group Nashville badges by series (same order as existing series)
    final seriesOrder = ['Schedule Builder', 'Conference Explorer',
        'Dedicated Attendee', 'Mystery'];
    final byS = <String, List<(String, String, String, int, bool)>>{};
    for (final b in _nashvilleBadges) {
      byS.putIfAbsent(b.$3, () => []).add(b);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // Coming-soon banner — dark background for contrast
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1035),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text('🔮', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 10),
              const Text(
                'REDCap Con 2027 — Nashville, TN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'New badge challenges drop when the 2027 schedule goes live.\n'
                'Your 2026 earned badges are preserved in the 2026 tab.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.75),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        // Points/progress placeholder
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('0',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface.withValues(alpha: 0.3),
                          height: 1)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, left: 4),
                    child: Text('/ ${BadgeService.maxPoints} pts',
                        style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5))),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0,
                  minHeight: 7,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      cs.primary.withValues(alpha: 0.25)),
                ),
              ),
              const SizedBox(height: 5),
              Text('0 of ${_nashvilleBadges.length} badges earned',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5))),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Nashville series sections
        for (final seriesName in seriesOrder)
          if (byS.containsKey(seriesName))
            _buildNashvilleSeriesSection(context, cs, seriesName, byS[seriesName]!),

        // ── Grand Slam reward badge ───────────────────────────────────────
        _buildGrandSlamSection(context, cs),
      ],
    );
  }

  Widget _buildNashvilleSeriesSection(
    BuildContext context,
    ColorScheme cs,
    String seriesName,
    List<(String, String, String, int, bool)> badges,
  ) {
    final color = BadgeService.seriesColor(seriesName);
    final bonus = BadgeService.seriesBonuses[seriesName] ?? 0;
    final dimColor = cs.onSurface.withValues(alpha: 0.18);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            children: [
              Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.4),
                      shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(seriesName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface.withValues(alpha: 0.45))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (bonus > 0) ...[
                      Text('+$bonus pts  · ',
                          style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurface.withValues(alpha: 0.3))),
                    ],
                    Text('Coming Soon',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface.withValues(alpha: 0.35))),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: badges.map((b) {
              final (String name, String emoji, String _, int pts, bool isNew) = b;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                  colors: [dimColor, dimColor]),
                            ),
                            child: Center(
                              child: Text(emoji,
                                  style: TextStyle(
                                      fontSize: 24,
                                      color: Colors.white.withValues(alpha: 0.2))),
                            ),
                          ),
                          Text(emoji,
                              style: TextStyle(
                                  fontSize: 24,
                                  color: cs.onSurface.withValues(alpha: 0.2))),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              width: 18, height: 18,
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: cs.outline.withValues(alpha: 0.3)),
                              ),
                              child: Icon(Icons.schedule,
                                  size: 10,
                                  color: cs.onSurface.withValues(alpha: 0.4)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                              color: cs.onSurface.withValues(alpha: 0.45))),
                      const SizedBox(height: 2),
                      if (isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('✨ new',
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade300)),
                        )
                      else
                        Text('$pts pt${pts == 1 ? '' : 's'}',
                            style: TextStyle(
                                fontSize: 9,
                                color: cs.onSurface.withValues(alpha: 0.25))),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),
        const Divider(indent: 16, endIndent: 16, height: 1),
      ],
    );
  }

  Widget _buildGrandSlamSection(BuildContext context, ColorScheme cs) {
    final unlocked = _hasAll2026;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, size: 16, color: Color(0xFFB8860B)),
              const SizedBox(width: 6),
              Text('2026 Grand Slam Reward',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFB8860B))),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: unlocked
                  ? const Color(0xFFFFD700).withValues(alpha: 0.08)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: unlocked
                    ? const Color(0xFFFFD700).withValues(alpha: 0.6)
                    : cs.outline.withValues(alpha: 0.2),
                width: unlocked ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                // Badge circle
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: unlocked
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                              )
                            : LinearGradient(colors: [
                                cs.onSurface.withValues(alpha: 0.15),
                                cs.onSurface.withValues(alpha: 0.15),
                              ]),
                        boxShadow: unlocked
                            ? [BoxShadow(
                                color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                                blurRadius: 16, offset: const Offset(0, 4))]
                            : [],
                      ),
                      child: Center(
                        child: Text('🎖️',
                            style: TextStyle(
                                fontSize: 34,
                                color: unlocked ? null : Colors.transparent)),
                      ),
                    ),
                    if (!unlocked) ...[
                      Text('🎖️',
                          style: TextStyle(
                              fontSize: 34,
                              color: Colors.white.withValues(alpha: 0.15))),
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: cs.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: cs.outline.withValues(alpha: 0.3)),
                        ),
                        child: Icon(Icons.lock,
                            size: 13,
                            color: cs.onSurface.withValues(alpha: 0.4)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nashville Grand Slam',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: unlocked
                              ? const Color(0xFFB8860B)
                              : cs.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        unlocked
                            ? '🎉 All 16 REDCap Con 2026 badges earned!\nYou start 2027 with this exclusive badge.'
                            : 'Earn all 16 REDCap Con 2026 badges to\nunlock this exclusive 2027 starter badge.',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.45,
                          color: unlocked
                              ? const Color(0xFFB8860B).withValues(alpha: 0.85)
                              : cs.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: unlocked
                              ? const Color(0xFFFFD700).withValues(alpha: 0.15)
                              : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unlocked ? '★ 15 bonus pts' : '15 bonus pts  ·  locked',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: unlocked
                                ? const Color(0xFFB8860B)
                                : cs.onSurface.withValues(alpha: 0.3),
                          ),
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
    );
  }

  // ── 2026 tab — real earned data ───────────────────────────────────────────

  Widget _build2026Tab(BuildContext context, ColorScheme cs) {
    final series = BadgeService.badgesBySeries;
    final earnedCount = _earnedIds.length;
    final totalCount = BadgeService.allBadges.length;
    final totalPts = BadgeService.computeTotalPoints(_earnedIds);
    final pct = BadgeService.maxPoints == 0 ? 0.0 : totalPts / BadgeService.maxPoints;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Year label
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(20),
              ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, size: 14, color: cs.onPrimaryContainer),
                const SizedBox(width: 6),
                Text('REDCap Con 2026  —  Your earned badges',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer)),
              ],
            ),
          ),
        ),

        // Points bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$totalPts',
                      style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold,
                          color: cs.primary, height: 1)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, left: 4),
                    child: Text('/ ${BadgeService.maxPoints} pts',
                        style: TextStyle(
                            fontSize: 13, color: cs.onSurfaceVariant)),
                  ),
                  const Spacer(),
                  Text('$earnedCount / $totalCount badges',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct, minHeight: 7,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        for (final entry in series.entries)
          _build2026SeriesSection(context, cs, entry.key, entry.value),
      ],
    );
  }

  Widget _build2026SeriesSection(
    BuildContext context, ColorScheme cs,
    String title, List<AppBadge> badges,
  ) {
    final color = BadgeService.seriesColor(title);
    final seriesEarned = badges.where((b) => _earnedIds.contains(b.id)).length;
    final bonus = BadgeService.seriesBonuses[title] ?? 0;
    final complete = seriesEarned == badges.length;
    final dimColor = cs.onSurface.withValues(alpha: 0.18);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            children: [
              Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold, color: cs.onSurface)),
              const Spacer(),
              if (bonus > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: complete
                        ? color.withValues(alpha: 0.18)
                        : cs.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    complete ? '+$bonus pts ★' : '+$bonus pts',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold,
                        color: complete ? color : cs.onSurface.withValues(alpha: 0.35)),
                  ),
                ),
              const SizedBox(width: 8),
              Text('$seriesEarned / ${badges.length}',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: complete ? color : cs.onSurfaceVariant)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: badges.map((badge) {
              final earned = _earnedIds.contains(badge.id);
              final year = _earnedYears[badge.id];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: earned
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [badge.seriesColor, badge.seriesColorDark])
                                  : LinearGradient(colors: [dimColor, dimColor]),
                              boxShadow: earned
                                  ? [BoxShadow(
                                      color: badge.seriesColor.withValues(alpha: 0.35),
                                      blurRadius: 8, offset: const Offset(0, 3))]
                                  : [],
                            ),
                            child: Center(
                              child: Text(badge.emoji,
                                  style: TextStyle(
                                      fontSize: 26,
                                      color: earned ? null : Colors.transparent)),
                            ),
                          ),
                          if (!earned) ...[
                            Text(badge.emoji,
                                style: TextStyle(fontSize: 26,
                                    color: Colors.white.withValues(alpha: 0.25))),
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                width: 18, height: 18,
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: cs.outline.withValues(alpha: 0.3)),
                                ),
                                child: Icon(Icons.lock, size: 10,
                                    color: cs.onSurface.withValues(alpha: 0.4)),
                              ),
                            ),
                          ],
                          if (earned && year != null)
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: badge.seriesColorDark,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      width: 1),
                                ),
                                child: Text("'${year % 100}",
                                    style: const TextStyle(
                                        fontSize: 8, fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(badge.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w600,
                              height: 1.2,
                              color: earned
                                  ? cs.onSurface
                                  : cs.onSurface.withValues(alpha: 0.38))),
                      const SizedBox(height: 2),
                      Text('${badge.points} pt${badge.points == 1 ? '' : 's'}',
                          style: TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w500,
                              color: earned
                                  ? badge.seriesColor
                                  : cs.onSurface.withValues(alpha: 0.25))),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),
        const Divider(indent: 16, endIndent: 16, height: 1),
      ],
    );
  }
}
