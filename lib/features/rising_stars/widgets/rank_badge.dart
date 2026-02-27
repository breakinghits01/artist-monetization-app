import 'package:flutter/material.dart';

/// Rank badge widget with animated trophy/medal icons
class RankBadge extends StatelessWidget {
  final int rank;
  final double size;

  const RankBadge({
    super.key,
    required this.rank,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    // Special styling for top 3
    if (rank <= 3) {
      return _buildTrophyBadge(context, rank);
    }

    // Regular rank number for others
    return _buildNumberBadge(context, rank);
  }

  Widget _buildTrophyBadge(BuildContext context, int rank) {
    Color badgeColor;
    IconData icon;
    Color iconColor;

    switch (rank) {
      case 1:
        badgeColor = const Color(0xFFFFD700); // Gold
        icon = Icons.emoji_events;
        iconColor = Colors.white;
        break;
      case 2:
        badgeColor = const Color(0xFFC0C0C0); // Silver
        icon = Icons.emoji_events;
        iconColor = Colors.white;
        break;
      case 3:
        badgeColor = const Color(0xFFCD7F32); // Bronze
        icon = Icons.emoji_events;
        iconColor = Colors.white;
        break;
      default:
        badgeColor = Colors.grey;
        icon = Icons.star;
        iconColor = Colors.white;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: badgeColor,
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: size * 0.6,
      ),
    );
  }

  Widget _buildNumberBadge(BuildContext context, int rank) {
    final theme = Theme.of(context);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
