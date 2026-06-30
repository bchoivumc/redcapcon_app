import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../services/schedule_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Appearance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Color Theme',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          _buildThemeOption(
            context,
            themeProvider,
            'professional',
            'REDCap Classic',
            'Dark red and neutral grays',
            [
              AppTheme.darkRed,
              AppTheme.brightRed,
              AppTheme.darkGray,
              AppTheme.mediumGray,
              AppTheme.lightGray,
            ],
          ),
          const SizedBox(height: 8),
          _buildThemeOption(
            context,
            themeProvider,
            'classic',
            'Burgundy Warm',
            'Burgundy and cream color scheme',
            [
              AppTheme.burgundy,
              AppTheme.red,
              AppTheme.cream,
              AppTheme.darkBlue,
              AppTheme.lightBlue,
            ],
          ),
          const SizedBox(height: 8),
          _buildThemeOption(
            context,
            themeProvider,
            'blue',
            'Modern Blue',
            'Slate and sky blue color scheme',
            [
              AppTheme.slate,
              AppTheme.slateBlue,
              AppTheme.skyBlue,
              AppTheme.offWhite,
              AppTheme.coral,
            ],
          ),
          const SizedBox(height: 8),
          _buildThemeOption(
            context,
            themeProvider,
            'earth',
            'Warm Earth',
            'Terracotta, gold, and forest green',
            [
              AppTheme.terracotta,
              AppTheme.beige,
              AppTheme.gold,
              AppTheme.forestGreen,
              AppTheme.brown,
            ],
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'About',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: const Text('App Version'),
            subtitle: Text(_version),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people_outline,
                          size: 15,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        'Acknowledgements',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Based on the Build Your Own Agenda app developed for REDCapCon 2025, '
                    'with contributions from Vanderbilt Health; '
                    'Marshfield Clinic Research Institute; '
                    'and The Ohio State University College of Medicine, Research Information '
                    'Technology (Jess Hale, lead developer)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (kDebugMode) ...[
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.bug_report,
                      size: 18, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Developer',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.delete_sweep_outlined,
                  color: Theme.of(context).colorScheme.error),
              title: Text(
                'Reset App State',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              subtitle: const Text('Clear all data — same as first install'),
              trailing: Icon(Icons.chevron_right,
                  color: Theme.of(context).colorScheme.error),
              onTap: () => _confirmReset(context),
            ),
          ],
          ListTile(
            leading: Icon(Icons.dashboard),
            title: const Text('2026 Con Dashboard'),
            subtitle: const Text('View conference dashboard'),
            trailing: Icon(Icons.open_in_new),
            onTap: () async {
              final url = Uri.parse('https://redcap.vumc.org/surveys/?__dashboard=7YEYW7CYA7F');
              try {
                final canLaunch = await canLaunchUrl(url);
                print('Can launch URL: $canLaunch');
                if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open dashboard')),
                    );
                  }
                }
              } catch (e) {
                print('Error launching URL: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded,
            color: Theme.of(ctx).colorScheme.error, size: 36),
        title: const Text('Reset Everything?'),
        content: const Text(
          'This clears your saved schedule, all badges, notification settings, '
          'and cached data — exactly like a fresh install.\n\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ScheduleService().masterReset();

    messenger.showSnackBar(
      const SnackBar(
        content: Text('App state reset — restart the app to start fresh.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeProvider themeProvider,
    String themeKey,
    String title,
    String description,
    List<Color> colors,
  ) {
    final isSelected = themeProvider.currentTheme == themeKey;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: InkWell(
        onTap: () => themeProvider.setTheme(themeKey),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: colors.map((color) {
                        return Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.1),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
