import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

/// Horizontal banner layout for treasure chest (desktop/tablet)
class TreasureChestBanner extends ConsumerWidget {
  const TreasureChestBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // Calculate treasure chest status
    final totalUploads = user?['totalUploads'] as int? ?? 0;
    final uploadsNeeded = 10;
    final progress = (totalUploads / uploadsNeeded).clamp(0.0, 1.0);
    final uploadsRemaining = (uploadsNeeded - totalUploads).clamp(0, uploadsNeeded);
    final canUnlock = totalUploads >= uploadsNeeded;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.15),
            theme.colorScheme.secondary.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Treasure Chest Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              canUnlock ? Icons.lock_open_rounded : Icons.lock_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 24),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Treasure Chest',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (canUnlock) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'READY',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  canUnlock
                      ? 'Congratulations! Unlock your reward now!'
                      : 'Upload $uploadsRemaining more song${uploadsRemaining != 1 ? 's' : ''} to unlock rewards',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                // Progress Bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor:
                              theme.colorScheme.surfaceVariant.withOpacity(0.5),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            canUnlock
                                ? theme.colorScheme.primary
                                : theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '$totalUploads / $uploadsNeeded',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 24),

          // Action Button
          ElevatedButton.icon(
            onPressed: canUnlock
                ? () {
                    // TODO: Implement unlock functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unlock treasure chest functionality'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                : null,
            icon: Icon(canUnlock ? Icons.redeem_rounded : Icons.upload_rounded),
            label: Text(canUnlock ? 'Unlock Now' : 'Upload More'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
