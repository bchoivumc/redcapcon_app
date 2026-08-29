import 'dart:async';
import 'dart:math';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../models/badge_model.dart';
import '../services/badge_service.dart';
import 'badges_2027_preview_screen.dart';

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
  bool _isFlipped = false;
  late final StreamSubscription<AppBadge> _badgeSub;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _badgeSub = BadgeService().onBadgeAwarded.listen((_) => _load());
  }

  @override
  void dispose() {
    _badgeSub.cancel();
    _scrollController.dispose();
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

  // ── Easter egg triggers ───────────────────────────────────────────────────

  // Phantom: briefly shows 2027 badge preview for 2 seconds then auto-pops.
  void _triggerPhantom() {
    final nav = Navigator.of(context);
    nav.push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const Badges2027PreviewScreen(),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    ));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && nav.canPop()) nav.pop();
    });
  }

  // Flip Flopper: mirrors the badge screen horizontally for 2 seconds.
  void _triggerFlipFlopper() {
    setState(() => _isFlipped = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isFlipped = false);
    });
  }

  // Blitz: full-screen snow + wind particle storm across all screens for 10s.
  void _triggerBlitz() {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _SnowWindOverlay(onDone: () => entry.remove()),
    );
    Overlay.of(context).insert(entry);
  }

  void _triggerContinental() {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ContinentalOverlay(onDone: () => entry.remove()),
    );
    Overlay.of(context).insert(entry);
  }

  VoidCallback? _longPressFor(AppBadge badge) {
    if (!_earnedIds.contains(badge.id)) return null;
    switch (badge.id) {
      case 'phantom':       return _triggerPhantom;
      case 'flip_flopper':  return _triggerFlipFlopper;
      case 'blitz':         return _triggerBlitz;
      case 'continental':   return _triggerContinental;
      default:              return null;
    }
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
      body: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..scale(_isFlipped ? -1.0 : 1.0, 1.0, 1.0),
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _PointsProgressBar(
              pts: _totalPts,
              maxPts: BadgeService.maxPoints,
              earnedCount: earnedCount,
              totalCount: totalCount,
              earnedIds: _earnedIds,
            ),
            const SizedBox(height: 8),
            for (final entry in series.entries)
              _SeriesSection(
                title: entry.key,
                badges: entry.value,
                earnedIds: _earnedIds,
                earnedYears: _earnedYears,
                onTap: _showDetail,
                longPressFor: _longPressFor,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Earned chip ───────────────────────────────────────────────────────────────

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
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
    final bySeriesMap    = BadgeService.badgesBySeries;
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
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
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
  final VoidCallback? Function(AppBadge) longPressFor;

  const _SeriesSection({
    required this.title,
    required this.badges,
    required this.earnedIds,
    required this.earnedYears,
    required this.onTap,
    required this.longPressFor,
  });

  @override
  Widget build(BuildContext context) {
    final color        = BadgeService.seriesColor(title);
    final seriesEarned = badges.where((b) => earnedIds.contains(b.id)).length;
    final complete     = seriesEarned == badges.length;
    final bonus        = BadgeService.seriesBonuses[title] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      )),
              const Spacer(),
              if (bonus > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: complete
                        ? color.withValues(alpha: 0.18)
                        : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    complete ? '+$bonus pts ★' : '+$bonus pts',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: complete
                          ? color
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                '$seriesEarned / ${badges.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: complete ? color : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
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
                    key: ValueKey(badge.id),
                    badge: badge,
                    earned: earned,
                    earnedYear: year,
                    onTap: () => onTap(badge, earned),
                    onLongPress: longPressFor(badge),
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

// ── Badge tile ────────────────────────────────────────────────────────────────

class _BadgeTile extends StatefulWidget {
  final AppBadge badge;
  final bool earned;
  final int? earnedYear;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _BadgeTile({
    super.key,
    required this.badge,
    required this.earned,
    required this.earnedYear,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<_BadgeTile> createState() => _BadgeTileState();
}

class _BadgeTileState extends State<_BadgeTile>
    with SingleTickerProviderStateMixin {
  Timer? _holdTimer;
  late final AnimationController _progressCtrl;
  bool _holding = false;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _progressCtrl.dispose();
    super.dispose();
  }

  void _startHold(LongPressStartDetails _) {
    if (widget.onLongPress == null) return;
    setState(() => _holding = true);
    _progressCtrl.forward(from: 0);
    _holdTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _holding = false);
      _progressCtrl.reset();
      widget.onLongPress!();
    });
  }

  void _cancelHold([dynamic _]) {
    _holdTimer?.cancel();
    _holdTimer = null;
    if (!mounted) return;
    setState(() => _holding = false);
    _progressCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final dimColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.18);

    return GestureDetector(
      onTap: widget.onTap,
      onLongPressStart: widget.onLongPress != null ? _startHold : null,
      onLongPressEnd: widget.onLongPress != null ? _cancelHold : null,
      onLongPressCancel: widget.onLongPress != null ? _cancelHold : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
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
                    gradient: widget.earned
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [widget.badge.seriesColor, widget.badge.seriesColorDark],
                          )
                        : LinearGradient(colors: [dimColor, dimColor]),
                    boxShadow: widget.earned
                        ? [
                            BoxShadow(
                              color: widget.badge.seriesColor.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      widget.badge.emoji,
                      style: TextStyle(
                        fontSize: 26,
                        color: widget.earned ? null : Colors.transparent,
                      ),
                    ),
                  ),
                ),
                if (!widget.earned) ...[
                  Text(widget.badge.emoji,
                      style: TextStyle(
                          fontSize: 26,
                          color: Colors.white.withValues(alpha: 0.25))),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(Icons.lock, size: 10,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                    ),
                  ),
                ],
                if (widget.earned && widget.earnedYear != null)
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: widget.badge.seriesColorDark,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5), width: 1),
                      ),
                      child: Text(
                        "'${widget.earnedYear! % 100}",
                        style: const TextStyle(
                            fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                // Progress ring while holding
                if (_holding)
                  SizedBox(
                    width: 60, height: 60,
                    child: AnimatedBuilder(
                      animation: _progressCtrl,
                      builder: (_, __) => CircularProgressIndicator(
                        value: _progressCtrl.value,
                        strokeWidth: 3.5,
                        color: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              widget.badge.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.2,
                color: widget.earned
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${widget.badge.points} pt${widget.badge.points == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: widget.earned
                    ? widget.badge.seriesColor
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
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
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 80, height: 80,
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
          Text(
            badge.name,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
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
          ImageFiltered(
            imageFilter: earned
                ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
                : ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Text(
              earned ? badge.description : badge.howToEarn,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
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
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ],
          // Hint for earned mystery badges
          if (earned && badge.series == 'Mystery') ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app, size: 13, color: Colors.purple.shade300),
                const SizedBox(width: 4),
                Text(
                  'Hold 2s on the badge to activate its power',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.purple.shade300,
                      fontWeight: FontWeight.w500),
                ),
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

// ── Snow + wind overlay (Blitz Easter egg) ────────────────────────────────────

class _SnowParticle {
  final double x;      // initial x position (0.0–1.0 of screen width)
  final double speed;  // fall speed (fraction of height per second)
  final double drift;  // horizontal wind drift per second
  final double size;
  final double delay;  // start delay (0.0–0.4 of total duration)
  final double opacity;

  _SnowParticle(Random rng)
      : x = rng.nextDouble(),
        speed = 0.06 + rng.nextDouble() * 0.09,
        drift = 0.01 + rng.nextDouble() * 0.04, // rightward wind
        size = 2.0 + rng.nextDouble() * 4.5,
        delay = rng.nextDouble() * 0.4,
        opacity = 0.55 + rng.nextDouble() * 0.45;
}

class _SnowPainter extends CustomPainter {
  final List<_SnowParticle> particles;
  final double t; // 0.0–1.0 total animation progress

  _SnowPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    for (final p in particles) {
      final effective = ((t - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);
      if (effective <= 0) continue;
      final x = ((p.x + p.drift * effective * 10) % 1.2) * size.width;
      final y = -12.0 + p.speed * effective * 10 * size.height;
      if (y > size.height + 12) continue;
      // fade out in last 20% of animation
      final fade = t > 0.8 ? (1.0 - t) / 0.2 : 1.0;
      paint.color = Colors.white.withValues(alpha: p.opacity * fade);
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_SnowPainter old) => old.t != t;
}

class _SnowWindOverlay extends StatefulWidget {
  final VoidCallback onDone;
  const _SnowWindOverlay({required this.onDone});

  @override
  State<_SnowWindOverlay> createState() => _SnowWindOverlayState();
}

class _SnowWindOverlayState extends State<_SnowWindOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<_SnowParticle> _particles =
      List.generate(120, (_) => _SnowParticle(Random()));

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )
      ..addListener(() => setState(() {}))
      ..forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _SnowPainter(_particles, _ctrl.value),
        child: const SizedBox.expand(),
      ),
    );
  }
}

// ── Continental Easter Egg ────────────────────────────────────────────────────

class _ContinentalOverlay extends StatefulWidget {
  final VoidCallback onDone;
  const _ContinentalOverlay({required this.onDone});

  @override
  State<_ContinentalOverlay> createState() => _ContinentalOverlayState();
}

class _ContinentalOverlayState extends State<_ContinentalOverlay>
    with TickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _cardCtrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  bool _showCard = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut));
    _fade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);

    _confetti.play();

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _showCard = true);
        _cardCtrl.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 4200), () => widget.onDone());
  }

  @override
  void dispose() {
    _confetti.dispose();
    _cardCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Confetti burst from center
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.08,
                numberOfParticles: 22,
                maxBlastForce: 35,
                minBlastForce: 15,
                gravity: 0.2,
                colors: const [
                  Color(0xFFFFD700),
                  Color(0xFFFFFFFF),
                  Color(0xFF1A1A1A),
                  Color(0xFFB8860B),
                  Color(0xFFC0C0C0),
                ],
              ),
            ),
            // Hotel card
            if (_showCard)
              Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 36),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 28),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFFFD700), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.7),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'THE CONTINENTAL',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(height: 1, color: const Color(0xFFFFD700)),
                          const SizedBox(height: 16),
                          const Text(
                            'Your reservation is confirmed.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              letterSpacing: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No business may be conducted\non these grounds.',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
