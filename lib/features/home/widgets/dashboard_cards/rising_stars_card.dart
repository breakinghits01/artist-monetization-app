import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/dashboard_card_model.dart';

/// Rising Stars card for dashboard
class RisingStarsCard extends StatelessWidget {
  final DashboardCardModel card;

  const RisingStarsCard({
    super.key,
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardHeight = screenWidth > 900 ? 200.0 : 160.0;

    return Hero(
      tag: 'rising_stars_card',
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: isDark ? 4 : 2,
        child: InkWell(
          onTap: () => context.push('/rising-stars'),
          child: Container(
            height: cardHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withValues(alpha: 0.7),
                  Colors.orange.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Content
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Trophy icon badge
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Title
                      Text(
                        card.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Subtitle
                      Text(
                        card.subtitle ?? 'Top trending artists this month',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                // View icon
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.amber.shade700,
                      size: 20,
                    ),
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
