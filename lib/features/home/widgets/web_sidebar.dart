import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sidebar navigation for desktop/tablet layouts
class WebSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onNavigate;

  const WebSidebar({
    super.key,
    required this.selectedIndex,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.surface,
          ],
        ),
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // App Logo/Title
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Artist\nMonetization',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isActive: selectedIndex == 0,
                  onTap: () => onNavigate(0),
                ),
                _NavItem(
                  icon: Icons.explore_rounded,
                  label: 'Discover',
                  isActive: selectedIndex == 1,
                  onTap: () => onNavigate(1),
                ),
                _NavItem(
                  icon: Icons.upload_rounded,
                  label: 'Upload',
                  isActive: selectedIndex == 2,
                  onTap: () => onNavigate(2),
                ),
                _NavItem(
                  icon: Icons.people_rounded,
                  label: 'Connect',
                  isActive: selectedIndex == 3,
                  onTap: () => onNavigate(3),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isActive: selectedIndex == 4,
                  onTap: () => onNavigate(4),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Bottom spacing
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isActive
            ? theme.colorScheme.primaryContainer.withOpacity(0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
