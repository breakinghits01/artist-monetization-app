import 'package:flutter/material.dart';

import '../models/subscription_model.dart';

/// Small pill badge showing the user's subscription tier.
/// Suitable for profile headers, user cards, etc.
class TierBadgeWidget extends StatelessWidget {
  final SubscriptionTier tier;
  final bool compact;

  const TierBadgeWidget({
    super.key,
    required this.tier,
    this.compact = false,
  });

  Color get _color {
    switch (tier) {
      case SubscriptionTier.advanced:
        return const Color(0xFFFFD700);
      case SubscriptionTier.premium:
        return const Color(0xFF1DB954);
      case SubscriptionTier.free:
        return Colors.white24;
    }
  }

  IconData get _icon {
    switch (tier) {
      case SubscriptionTier.advanced:
        return Icons.workspace_premium_rounded;
      case SubscriptionTier.premium:
        return Icons.star_rounded;
      case SubscriptionTier.free:
        return Icons.person_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (tier == SubscriptionTier.free && !compact) {
      // Don't show a badge for free users unless explicitly requested
      return const SizedBox.shrink();
    }

    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _color, size: compact ? 12 : 14),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              tier.displayName,
              style: TextStyle(
                color: _color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
