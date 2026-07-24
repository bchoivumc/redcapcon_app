import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'theme/theme_provider.dart';
import 'theme/time_format_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TimeFormatProvider()),
      ],
      child: const REDCapConApp(),
    ),
  );

  // Initialize notifications in the background after the app starts.
  // We do NOT request permissions here — that happens later, on demand.
  NotificationService().initialize();
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
