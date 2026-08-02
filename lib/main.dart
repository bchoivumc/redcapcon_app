import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'theme/theme_provider.dart';
import 'theme/time_format_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const AppRestarter(child: _Providers()));

  // Initialize notifications in the background after the app starts.
  // We do NOT request permissions here — that happens later, on demand.
  NotificationService().initialize();
}

/// Wraps the entire app so the widget tree can be fully rebuilt on demand
/// (e.g. after restoring a backup) without closing and reopening the app.
class AppRestarter extends StatefulWidget {
  const AppRestarter({super.key, required this.child});
  final Widget child;

  static void restart(BuildContext context) {
    context.findAncestorStateOfType<_AppRestarterState>()?.restart();
  }

  @override
  State<AppRestarter> createState() => _AppRestarterState();
}

class _AppRestarterState extends State<AppRestarter> {
  Key _key = UniqueKey();

  void restart() => setState(() => _key = UniqueKey());

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _key, child: widget.child);
}

class _Providers extends StatelessWidget {
  const _Providers();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TimeFormatProvider()),
      ],
      child: const REDCapConApp(),
    );
  }
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
