import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../models/badge_model.dart';
import '../services/badge_service.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  Set<String> _earnedIds = {};
  Map<String, int> _earnedYears = {};
  int _totalPts = 0;
  bool _isLoading = true;
  late final StreamSubscription<AppBadge> _badgeSub;

  @override
  void initState() {
    super.initState();
    _load();
    // Refresh whenever a badge is earned while this screen is visible
    _badgeSub = BadgeService().onBadgeAwarded.listen((_) => _load());
  }

  @override
  void dispose() {
    _badgeSub.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final ids   = await BadgeService().getEarnedBadgeIds();
    final years = await BadgeService().getEarnedBadgeYears();
    if (mounted) {
      setState(() {
        _earnedIds   = ids;
        _earnedYears = years;
        _totalPts    = BadgeService.computeTotalPoints(ids);
        _isLoading   = false;
      });
    }
  }

  // ── Detail sheet ──────────────────────────────────────────────────────────

  void _showDetail(AppBadge badge, bool earned) {
    final color = earned ? badge.seriesColor : Colors.grey.shade500;
    final year  = _earnedYears[badge.id];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BadgeDetailSheet(
        badge: badge,
        earned: earned,
        earnedYear: year,
        color: color,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final earnedCount = _earnedIds.length;
    final totalCount  = BadgeService.allBadges.length;
    final series      = BadgeService.badgesBySeries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Badges'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _EarnedChip(earned: earnedCount, total: totalCount),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // ── Points progress ──────────────────────────────────────────────
          _PointsProgressBar(
            pts: _totalPts,
            maxPts: BadgeService.maxPoints,
            earnedCount: earnedCount,
            totalCount: totalCount,
            earnedIds: _earnedIds,
          ),
          const SizedBox(height: 8),

          // ── One section per series ───────────────────────────────────────
          for (final entry in series.entries) ...[
            _SeriesSection(
              title: entry.key,
              badges: entry.value,
              earnedIds: _earnedIds,
              earnedYears: _earnedYears,
              onTap: _showDetail,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Earned chip (AppBar action) ───────────────────────────────────────────────

class _EarnedChip extends StatelessWidget {
  final int earned;
  final int total;
  const _EarnedChip({required this.earned, required this.total});

  @override
  Widget build(BuildContext context) {
    final all = earned == total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: all
            ? const Color(0xFFFFD700).withValues(alpha: 0.2)
            : Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (all) const Text('★ ', style: TextStyle(fontSize: 12, color: Color(0xFFFFD700))),
          Text(
            '$earned / $total',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: all
                  ? const Color(0xFFB8860B)
                  : Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Points progress bar ───────────────────────────────────────────────────────

class _PointsProgressBar extends StatelessWidget {
  final int pts;
  final int maxPts;
  final int earnedCount;
  final int totalCount;
  final Set<String> earnedIds;

  const _PointsProgressBar({
    required this.pts,
    required this.maxPts,
    required this.earnedCount,
    required this.totalCount,
    required this.earnedIds,
  });

  @override
  Widget build(BuildContext context) {
    final pct     = maxPts == 0 ? 0.0 : pts / maxPts;
    final primary = Theme.of(context).colorScheme.primary;
    final isMax   = pts >= maxPts;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$pts',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isMax ? const Color(0xFFB8860B) : primary,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 3, left: 4),
                child: Text(
                  '/ $maxPts pts',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              if (isMax)
                const Text('🏅 Max!',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB8860B))),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 7,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                isMax ? const Color(0xFFFFD700) : primary,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Text(
                '$earnedCount of $totalCount badges earned',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const Spacer(),
              _AnyThreeBonusChip(earnedIds: earnedIds),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Any-3-series bonus chip ───────────────────────────────────────────────────

class _AnyThreeBonusChip extends StatelessWidget {
  final Set<String> earnedIds;
  const _AnyThreeBonusChip({required this.earnedIds});

  @override
  Widget build(BuildContext context) {
    final bySeriesMap = BadgeService.badgesBySeries;
    final completedCount = bySeriesMap.values
        .where((badges) => badges.every((b) => earnedIds.contains(b.id)))
        .length;
    final earned = completedCount >= 3;
    final bonus  = BadgeService.anyThreeSeriesBonus;
    final color  = earned
        ? const Color(0xFFB8860B)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: earned
            ? const Color(0xFFFFD700).withValues(alpha: 0.15)
            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        earned ? '+$bonus pts bonus ★' : 'Complete 3 series: +$bonus pts',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

// ── Series section ────────────────────────────────────────────────────────────

class _SeriesSection extends StatelessWidget {
  final String title;
  final List<AppBadge> badges;
  final Set<String> earnedIds;
  final Map<String, int> earnedYears;
  final void Function(AppBadge, bool) onTap;

  const _SeriesSection({
    required this.title,
    required this.badges,
    required this.earnedIds,
    required this.earnedYears,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color         = BadgeService.seriesColor(title);
    final seriesEarned  = badges.where((b) => earnedIds.contains(b.id)).length;
    final complete      = seriesEarned == badges.length;
    final bonus         = BadgeService.seriesBonuses[title] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const Spacer(),
              // Series bonus pill — hidden when series has no bonus (Mystery)
              if (bonus > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: complete
                        ? color.withValues(alpha: 0.18)
                        : Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    complete ? '+$bonus pts ★' : '+$bonus pts',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: complete
                          ? color
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.35),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                '$seriesEarned / ${badges.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: complete
                      ? color
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Badge row (4-column grid)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: badges.map((badge) {
              final earned = earnedIds.contains(badge.id);
              final year   = earnedYears[badge.id];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _BadgeTile(
                    badge: badge,
                    earned: earned,
                    earnedYear: year,
                    onTap: () => onTap(badge, earned),
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

// ── Badge tile (compact) ──────────────────────────────────────────────────────

class _BadgeTile extends StatelessWidget {
  final AppBadge badge;
  final bool earned;
  final int? earnedYear;
  final VoidCallback onTap;

  const _BadgeTile({
    required this.badge,
    required this.earned,
    required this.earnedYear,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dimColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.18);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji circle
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
                            colors: [badge.seriesColor, badge.seriesColorDark],
                          )
                        : LinearGradient(colors: [dimColor, dimColor]),
                    boxShadow: earned
                        ? [
                            BoxShadow(
                              color: badge.seriesColor.withValues(alpha: 0.35),
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
                // Lock icon / dim emoji for unearned
                if (!earned) ...[
                  Text(badge.emoji,
                      style: TextStyle(
                          fontSize: 26,
                          color: Colors.white.withValues(alpha: 0.25))),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(Icons.lock,
                          size: 10,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4)),
                    ),
                  ),
                ],
                // Year tag for earned
                if (earned && earnedYear != null)
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
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 1),
                      ),
                      child: Text(
                        "'${earnedYear! % 100}",
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

            // Badge name
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
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.38),
              ),
            ),

            const SizedBox(height: 2),

            // Points chip
            Text(
              '${badge.points} pt${badge.points == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: earned
                    ? badge.seriesColor
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge detail bottom sheet ─────────────────────────────────────────────────

class _BadgeDetailSheet extends StatelessWidget {
  final AppBadge badge;
  final bool earned;
  final int? earnedYear;
  final Color color;

  const _BadgeDetailSheet({
    required this.badge,
    required this.earned,
    required this.earnedYear,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Emoji
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: earned
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [badge.seriesColor, badge.seriesColorDark],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF9E9E9E), Color(0xFF616161)]),
              boxShadow: earned
                  ? [
                      BoxShadow(
                          color: badge.seriesColor.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4))
                    ]
                  : [],
            ),
            child: Center(
              child: Text(badge.emoji, style: const TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 14),

          // Name
          Text(
            badge.name,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),

          // Series + year + points pill row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Pill(label: badge.series, color: color),
              const SizedBox(width: 6),
              _Pill(
                label: '${badge.points} pt${badge.points == 1 ? '' : 's'}',
                color: earned ? color : Colors.grey.shade500,
                icon: Icons.star_outline,
              ),
              if (earned && earnedYear != null) ...[
                const SizedBox(width: 6),
                _Pill(
                  label: 'Earned \'${earnedYear! % 100}',
                  color: Colors.green.shade600,
                  icon: Icons.check_circle_outline,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Description / hint (blurred until earned)
          ImageFiltered(
            imageFilter: earned
                ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
                : ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Text(
              earned ? badge.description : badge.howToEarn,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.75),
                  ),
            ),
          ),

          if (!earned) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text('Earn this badge to reveal',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ],

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: earned ? badge.seriesColor : null,
              ),
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _Pill({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
