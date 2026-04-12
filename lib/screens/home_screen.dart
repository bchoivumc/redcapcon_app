import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'agenda_screen.dart';
import 'my_schedule_screen.dart';
import 'search_screen.dart';
import 'timeline_view_screen.dart';
import 'badges_screen.dart';
import '../models/badge_model.dart';
import '../services/badge_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _selectedYear = 2026;

  final GlobalKey<AgendaScreenState>       _agendaKey     = GlobalKey<AgendaScreenState>();
  final GlobalKey<MyScheduleScreenState>   _myScheduleKey = GlobalKey<MyScheduleScreenState>();
  final GlobalKey<TimelineViewScreenState> _timelineKey   = GlobalKey<TimelineViewScreenState>();

  // ── Time tracking ──────────────────────────────────────────────────────────
  DateTime? _foregroundSince;
  late final StreamSubscription<AppBadge> _badgeSub;

  // ── Badge award queue (prevents simultaneous dialogs) ─────────────────────
  final List<AppBadge> _badgeQueue = [];
  bool _showingBadge = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foregroundSince = DateTime.now();

    // Time-of-day badges (early bird / night owl / phantom) on every open
    BadgeService().checkTimeOfDayBadges();

    // Track initial tab (Agenda = 0)
    BadgeService().trackTabVisit(0);


    // Listen for newly earned badges and show overlay
    _badgeSub = BadgeService().onBadgeAwarded.listen(_showBadgeAward);
  }

  @override
  void dispose() {
    _flushTime();
    WidgetsBinding.instance.removeObserver(this);
    _badgeSub.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foregroundSince = DateTime.now();
      BadgeService().checkTimeOfDayBadges();
    } else if (state == AppLifecycleState.paused) {
      _flushTime();
    }
  }

  void _flushTime() {
    if (_foregroundSince == null) return;
    final minutes = DateTime.now().difference(_foregroundSince!).inMinutes;
    _foregroundSince = null;
    if (minutes > 0) BadgeService().addAppMinutes(minutes);
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    BadgeService().trackTabVisit(index);
  }

  void _onYearChanged(int year) {
    setState(() => _selectedYear = year);
  }

  // ── Badge award overlay (queued to prevent simultaneous dialogs) ──────────

  void _showBadgeAward(AppBadge badge) {
    if (!mounted) return;
    _badgeQueue.add(badge);
    if (!_showingBadge) _showNextBadge();
  }

  void _showNextBadge() {
    if (_badgeQueue.isEmpty || !mounted) {
      _showingBadge = false;
      return;
    }
    _showingBadge = true;
    final badge = _badgeQueue.removeAt(0);
    HapticFeedback.lightImpact();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _BadgeToast(
        badge: badge,
        onDone: () {
          entry.remove();
          _showingBadge = false;
          _showNextBadge();
        },
      ),
    );
    Overlay.of(context).insert(entry);
  }

  void _onYearChanged(int year) {
    setState(() {
      _selectedYear = year;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      AgendaScreen(
        key: _agendaKey,
        selectedYear: _selectedYear,
        onYearChanged: _onYearChanged,
      ),
      TimelineViewScreen(
        key: _timelineKey,
        selectedYear: _selectedYear,
      ),
      const SearchScreen(),
      const BadgesScreen(),
      MyScheduleScreen(key: _myScheduleKey),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_timeline),
            selectedIcon: Icon(Icons.view_timeline),
            label: 'Timeline',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.workspace_premium_outlined),
            selectedIcon: Icon(Icons.workspace_premium),
            label: 'Badges',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: 'My Schedule',
          ),
        ],
      ),
    );
  }
}

class _BadgeToast extends StatefulWidget {
  final AppBadge badge;
  final VoidCallback onDone;
  const _BadgeToast({required this.badge, required this.onDone});

  @override
  State<_BadgeToast> createState() => _BadgeToastState();
}

class _BadgeToastState extends State<_BadgeToast> with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final ConfettiController _confetti;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(milliseconds: 900));
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _slide = Tween(begin: const Offset(0, 1.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward().then((_) => _confetti.play());
    Future.delayed(const Duration(milliseconds: 3200), _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    _confetti.stop();
    await _ctrl.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = widget.badge;
    final bottom = MediaQuery.of(context).padding.bottom + 16;
    return Positioned(
      bottom: bottom,
      left: 16,
      right: 16,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 5,
            maxBlastForce: 10,
            minBlastForce: 3,
            emissionFrequency: 0.02,
            gravity: 0.5,
            particleDrag: 0.08,
            colors: [
              badge.seriesColor,
              Colors.amber,
              Colors.white,
            ],
          ),
          SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: GestureDetector(
                onTap: _dismiss,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Color.lerp(badge.seriesColor, Colors.white, 0.82)!,
                          Color.lerp(badge.seriesColor, Colors.white, 0.68)!,
                          Color.lerp(badge.seriesColorDark, Colors.white, 0.55)!,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(badge.emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Badge Unlocked',
                              style: TextStyle(
                                fontSize: 11,
                                color: badge.seriesColorDark.withValues(alpha: 0.75),
                              ),
                            ),
                            Text(
                              badge.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: badge.seriesColorDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

