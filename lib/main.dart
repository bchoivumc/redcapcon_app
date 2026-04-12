import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'theme/theme_provider.dart';
import 'services/notification_service.dart';
import 'services/schedule_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service (non-blocking - errors won't crash the app)
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.requestPermissions();

    // Reschedule all saved sessions in case notifications were previously
    // scheduled with wrong times (CDT stored-as-UTC bug, fixed in cache v8)
    await ScheduleService().rescheduleAllNotifications();
  } catch (e) {
    print('Failed to initialize notifications: $e');
    // Continue running the app even if notifications fail
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const REDCapConApp(),
    ),
  );
}

class REDCapConApp extends StatelessWidget {
  const REDCapConApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'REDCap Con',
      theme: themeProvider.themeData,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
