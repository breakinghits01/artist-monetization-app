import 'package:flutter/material.dart';
import '../../models/dashboard_card_model.dart';

/// Artist spotlight card widget
class ArtistSpotlightCard extends StatelessWidget {
  final DashboardCardModel card;

  const ArtistSpotlightCard({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isDark ? 4 : 2,
      child: InkWell(
        onTap: () {
          // Navigate to artist profile
        },
        child: Container(
          height: 220,
          decoration: BoxDecoration(color: theme.colorScheme.surface),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Artist image placeholder
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.3),
                        theme.colorScheme.secondary.withValues(alpha: 0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person,
                      size: 64,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              // Artist info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.subtitle ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text('Follow'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.card_giftcard, size: 20),
                          onPressed: () {},
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                          ),
                          tooltip: 'Tip Artist',
                        ),
                      ],
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
