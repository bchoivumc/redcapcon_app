import 'package:flutter/material.dart';
import 'agenda_screen.dart';
import 'my_schedule_screen.dart';
import 'search_screen.dart';
import 'timeline_view_screen.dart';
import '../services/schedule_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final ScheduleService _scheduleService = ScheduleService();
  final GlobalKey<AgendaScreenState> _agendaKey = GlobalKey<AgendaScreenState>();
  final GlobalKey<MyScheduleScreenState> _myScheduleKey = GlobalKey<MyScheduleScreenState>();

  @override
  void initState() {
    super.initState();
    // Register lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    // Check for updates on first load
    _checkForUpdatesOnResume();
  }

  @override
  void dispose() {
    // Unregister lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Check for updates when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _checkForUpdatesOnResume();
    }
  }

  /// Check for schedule updates when app resumes
  Future<void> _checkForUpdatesOnResume() async {
    try {
      final hasUpdates = await _scheduleService.checkForUpdates();

      if (hasUpdates && mounted) {
        // Automatically refresh the schedule
        _agendaKey.currentState?.refreshSchedule();

        // Notify user that schedule was updated
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule updated with latest changes'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Silently fail - don't bother user if update check fails
      print('Update check failed: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      AgendaScreen(key: _agendaKey),
      const TimelineViewScreen(),
      const SearchScreen(),
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
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: 'My Schedule',
          ),
        ],
      ),
    );
  }
}
