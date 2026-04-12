import 'package:flutter/material.dart';
import 'agenda_screen.dart';
import 'my_schedule_screen.dart';
import 'search_screen.dart';
import 'timeline_view_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _selectedYear = 2026; // Shared year state
  final GlobalKey<AgendaScreenState> _agendaKey = GlobalKey<AgendaScreenState>();
  final GlobalKey<MyScheduleScreenState> _myScheduleKey = GlobalKey<MyScheduleScreenState>();
  final GlobalKey<TimelineViewScreenState> _timelineKey = GlobalKey<TimelineViewScreenState>();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
