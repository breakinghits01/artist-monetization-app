import 'package:flutter/material.dart';
import '../../../../shared/widgets/token_icon.dart';
import '../../models/dashboard_card_model.dart';

/// Daily challenge card widget
class ChallengeCard extends StatelessWidget {
  final DashboardCardModel card;

  const ChallengeCard({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final metadata = card.metadata ?? {};
    final current = metadata['current'] as int? ?? 0;
    final target = metadata['target'] as int? ?? 5;
    final progress = current / target;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isDark ? 4 : 2,
      child: InkWell(
        onTap: () {
          // Navigate to challenge details
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Challenge icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🏆', style: TextStyle(fontSize: 32)),
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                card.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$current / $target',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const TokenIcon(size: 16, withShadow: false),
                          const SizedBox(width: 4),
                          Text(
                            '${metadata['reward'] ?? 0}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFFD700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.primary.withOpacity(
                        0.1,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
