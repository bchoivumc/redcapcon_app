import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: Icon(Icons.event),
            title: const Text('REDCap Conference'),
            subtitle: const Text('Official conference schedule app'),
          ),
        ],
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
