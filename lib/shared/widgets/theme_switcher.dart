import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_provider.dart';

/// Theme Switcher Widget
/// 
/// A reusable widget that allows users to toggle between light and dark themes.
/// Can be used as an icon button, switch, or custom UI element.
class ThemeSwitcher extends ConsumerWidget {
  final ThemeSwitcherType type;
  final String? tooltip;
  final bool showLabel;

  const ThemeSwitcher({
    super.key,
    this.type = ThemeSwitcherType.iconButton,
    this.tooltip,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    switch (type) {
      case ThemeSwitcherType.iconButton:
        return _buildIconButton(context, ref, isDarkMode);
      case ThemeSwitcherType.switchToggle:
        return _buildSwitch(context, ref, isDarkMode);
      case ThemeSwitcherType.card:
        return _buildCard(context, ref, isDarkMode);
    }
  }

  Widget _buildIconButton(BuildContext context, WidgetRef ref, bool isDarkMode) {
    return IconButton(
      icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
      onPressed: () {
        ref.read(themeModeProvider.notifier).toggleTheme();
      },
      tooltip: tooltip ?? (isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode'),
    );
  }

  Widget _buildSwitch(BuildContext context, WidgetRef ref, bool isDarkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) ...[
          Icon(
            Icons.light_mode,
            size: 20,
            color: !isDarkMode ? Theme.of(context).colorScheme.primary : null,
          ),
          const SizedBox(width: 8),
        ],
        Switch(
          value: isDarkMode,
          onChanged: (value) {
            ref.read(themeModeProvider.notifier).toggleTheme();
          },
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.dark_mode,
            size: 20,
            color: isDarkMode ? Theme.of(context).colorScheme.primary : null,
          ),
        ],
      ],
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, bool isDarkMode) {
    return Card(
      child: InkWell(
        onTap: () {
          ref.read(themeModeProvider.notifier).toggleTheme();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isDarkMode ? 'Dark Mode' : 'Light Mode',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch(
                value: isDarkMode,
                onChanged: (value) {
                  ref.read(themeModeProvider.notifier).toggleTheme();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Theme Switcher Types
enum ThemeSwitcherType {
  /// Simple icon button (default)
  iconButton,
  
  /// Switch toggle with optional labels
  switchToggle,
  
  /// Card with description
  card,
}
