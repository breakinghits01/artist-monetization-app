import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/token_icon.dart';
import '../models/wallet_model.dart';
import '../providers/wallet_provider.dart';

/// Animated wallet header showing tokens and balance
class WalletHeader extends ConsumerWidget {
  const WalletHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final wallet = ref.watch(walletProvider);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  theme.colorScheme.primary.withOpacity(0.2),
                  theme.colorScheme.secondary.withOpacity(0.1),
                ]
              : [
                  theme.colorScheme.primary.withOpacity(0.1),
                  theme.colorScheme.secondary.withOpacity(0.05),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: wallet.when(
          data: (walletData) => _buildWalletContent(
            context,
            theme,
            walletData,
            0, // No unread count for now
            isDark,
          ),
          loading: () => _buildLoadingState(theme),
          error: (error, stack) => _buildErrorState(theme),
        ),
      ),
    );
  }

  Widget _buildWalletContent(
    BuildContext context,
    ThemeData theme,
    WalletModel wallet,
    int unreadCount,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and notification
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dynamic Artist Monetization',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your Daily Music Treasure',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            // Notification bell
            Stack(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: () {
                    // Navigate to notifications
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 1.5,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Wallet stats
        Row(
          children: [
            // Tokens
            Expanded(
              child: _WalletStatCard(
                icon: null,
                customIcon: const TokenIcon(size: 32),
                label: 'Tokens',
                value: wallet.formattedTokens,
                color: const Color(0xFFFFD700), // Gold
                onTap: () {
                  // Show token details
                },
              ),
            ),
            const SizedBox(width: 12),
            // Balance
            Expanded(
              child: _WalletStatCard(
                icon: '💵',
                label: 'Balance',
                value: wallet.formattedBalance,
                color: const Color(0xFF4CAF50), // Green
                onTap: () {
                  // Show balance details
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 200,
                  height: 16,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 150,
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(
            2,
            (index) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < 1 ? 12 : 0),
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Text(
        'Failed to load wallet',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}

/// Wallet stat card widget
class _WalletStatCard extends StatelessWidget {
  final String? icon;
  final Widget? customIcon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _WalletStatCard({
    this.icon,
    this.customIcon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surface.withOpacity(0.5)
                : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (customIcon != null)
                customIcon!
              else if (icon != null)
                Text(icon!, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
