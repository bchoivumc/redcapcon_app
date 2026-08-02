import 'package:flutter/material.dart';
import '../models/badge_model.dart';
import '../services/badge_service.dart';

/// Debug-only sneak peek of the proposed multi-year badge screen layout.
/// Tab 1 — 2027: upcoming badges (all locked, "coming soon" treatment).
/// Tab 2 — 2026: real earned badges from this year.
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
            Tab(text: 'REDCap Con 2027'),
            Tab(text: 'REDCap Con 2026'),
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

  // ── 2027 tab — coming soon ────────────────────────────────────────────────

  Widget _build2027Tab(BuildContext context, ColorScheme cs) {
    final series = BadgeService.badgesBySeries;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Coming soon banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primaryContainer, cs.secondaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text('🔮', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              Text(
                'REDCap Con 2027 Badges',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onPrimaryContainer,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'New badge challenges drop when the 2027 schedule goes live.\n'
                'Your 2026 earned badges are preserved in the next tab.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onPrimaryContainer.withValues(alpha: 0.75),
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ),

        // Points bar placeholder
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '0',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface.withValues(alpha: 0.3),
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, left: 4),
                    child: Text(
                      '/ ${BadgeService.maxPoints} pts',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
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
                    cs.primary.withValues(alpha: 0.3),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '0 of ${BadgeService.allBadges.length} badges earned',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Series sections — all locked
        for (final entry in series.entries)
          _buildSeriesSection(
            context: context,
            cs: cs,
            title: entry.key,
            badges: entry.value,
            earnedIds: const {},
            earnedYears: const {},
            comingSoon: true,
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

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Year badge
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'REDCap Con 2026  —  Earned badges',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Points bar (real 2026 data)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$totalPts',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, left: 4),
                    child: Text(
                      '/ ${BadgeService.maxPoints} pts',
                      style:
                          TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$earnedCount / $totalCount badges',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: BadgeService.maxPoints == 0
                      ? 0
                      : totalPts / BadgeService.maxPoints,
                  minHeight: 7,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        for (final entry in series.entries)
          _buildSeriesSection(
            context: context,
            cs: cs,
            title: entry.key,
            badges: entry.value,
            earnedIds: _earnedIds,
            earnedYears: _earnedYears,
            comingSoon: false,
          ),
      ],
    );
  }

  // ── Shared series section ─────────────────────────────────────────────────

  Widget _buildSeriesSection({
    required BuildContext context,
    required ColorScheme cs,
    required String title,
    required List<AppBadge> badges,
    required Set<String> earnedIds,
    required Map<String, int> earnedYears,
    required bool comingSoon,
  }) {
    final color = BadgeService.seriesColor(title);
    final seriesEarned = badges.where((b) => earnedIds.contains(b.id)).length;
    final bonus = BadgeService.seriesBonuses[title] ?? 0;
    final complete = !comingSoon && seriesEarned == badges.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: comingSoon
                      ? color.withValues(alpha: 0.35)
                      : color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: comingSoon
                          ? cs.onSurface.withValues(alpha: 0.4)
                          : cs.onSurface,
                    ),
              ),
              const Spacer(),
              if (comingSoon)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
                )
              else ...[
                if (bonus > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: complete
                          ? color.withValues(alpha: 0.18)
                          : cs.surfaceContainerHighest.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      complete ? '+$bonus pts ★' : '+$bonus pts',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: complete
                            ? color
                            : cs.onSurface.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  '$seriesEarned / ${badges.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: complete ? color : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: badges.map((badge) {
              final earned = !comingSoon && earnedIds.contains(badge.id);
              final year = earnedYears[badge.id];
              final dimColor = cs.onSurface.withValues(alpha: 0.18);

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
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: earned
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        badge.seriesColor,
                                        badge.seriesColorDark
                                      ],
                                    )
                                  : LinearGradient(
                                      colors: [dimColor, dimColor]),
                              boxShadow: earned
                                  ? [
                                      BoxShadow(
                                        color: badge.seriesColor
                                            .withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                badge.emoji,
                                style: TextStyle(
                                  fontSize: 26,
                                  color: earned ? null : Colors.transparent,
                                ),
                              ),
                            ),
                          ),
                          if (!earned) ...[
                            Text(badge.emoji,
                                style: TextStyle(
                                    fontSize: 26,
                                    color:
                                        Colors.white.withValues(alpha: 0.25))),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: cs.outline.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Icon(
                                  comingSoon ? Icons.schedule : Icons.lock,
                                  size: 10,
                                  color: cs.onSurface.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ],
                          if (earned && year != null)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: badge.seriesColorDark,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.5),
                                      width: 1),
                                ),
                                child: Text(
                                  "'${year % 100}",
                                  style: const TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        badge.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          color: earned
                              ? cs.onSurface
                              : cs.onSurface.withValues(alpha: 0.38),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${badge.points} pt${badge.points == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: earned
                              ? badge.seriesColor
                              : cs.onSurface.withValues(alpha: 0.25),
                        ),
                      ),
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
