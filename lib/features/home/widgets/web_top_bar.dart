import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

/// Top bar for desktop/tablet layouts
class WebTopBar extends ConsumerWidget {
  const WebTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            // Search Bar
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search songs, artists, playlists...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (value) {
                    // TODO: Implement search functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Search: $value'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(width: 24),

            // Wallet Balance
            if (user?['walletBalance'] != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₱${(user!['walletBalance'] as num).toStringAsFixed(2)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(width: 16),

            // User Profile
            PopupMenuButton<String>(
              offset: const Offset(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      const Icon(Icons.person_rounded),
                      const SizedBox(width: 12),
                      Text('Profile', style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      const Icon(Icons.settings_rounded),
                      const SizedBox(width: 12),
                      Text('Settings', style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: theme.colorScheme.error),
                      const SizedBox(width: 12),
                      Text(
                        'Logout',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'profile':
                    // TODO: Navigate to profile
                    break;
                  case 'settings':
                    // TODO: Navigate to settings
                    break;
                  case 'logout':
                    ref.read(authProvider.notifier).logout();
                    break;
                }
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: user?['profilePicture'] != null
                        ? NetworkImage(user!['profilePicture'] as String)
                        : null,
                    child: user?['profilePicture'] == null
                        ? Text(
                            (user?['displayName'] as String?)?.substring(0, 1).toUpperCase() ??
                                'U',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?['displayName'] as String? ?? 'User',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        user?['username'] as String? ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_drop_down_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
