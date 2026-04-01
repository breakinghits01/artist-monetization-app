import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';

/// Bottom sheet shown when a Free-tier user taps Download.
/// Explains the benefit and gives a direct path to the plans screen.
class UpgradePromptWidget extends StatelessWidget {
  /// Friendly description of the locked feature, e.g. "Download songs"
  final String featureDescription;

  const UpgradePromptWidget({
    super.key,
    this.featureDescription = 'Download songs for offline listening',
  });

  /// Convenience: show this widget as a modal bottom sheet
  static Future<void> show(
    BuildContext context, {
    String featureDescription = 'Download songs for offline listening',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpgradePromptWidget(
        featureDescription: featureDescription,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Lock icon with glow
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1DB954).withOpacity(0.12),
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: Color(0xFF1DB954),
              size: 36,
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Premium Feature',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            featureDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          // Benefits list
          _BenefitRow(icon: Icons.download_rounded, text: 'Download up to 100 songs (Premium) or unlimited (Advanced)'),
          _BenefitRow(icon: Icons.music_note_rounded, text: 'High-quality audio up to Lossless'),
          _BenefitRow(icon: Icons.block_rounded, text: 'Ad-free, uninterrupted listening'),
          const SizedBox(height: 28),

          // CTA — go to plans
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // dismiss sheet
                context.push(AppConstants.plansRoute);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                elevation: 0,
              ),
              child: const Text(
                'View Plans',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Dismiss
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Not now',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1DB954), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
