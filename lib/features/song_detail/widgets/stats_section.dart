import 'package:flutter/material.dart';
import '../../player/models/song_model.dart';
import '../../../shared/widgets/token_icon.dart';
import '../../../core/theme/app_colors_extension.dart';

/// Stats section displaying engagement metrics
class StatsSection extends StatelessWidget {
  final SongModel song;

  const StatsSection({
    super.key,
    required this.song,
  });

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        spacing: isDesktop ? 32 : 16,
        runSpacing: 16,
        children: [
          // Play Count
          _StatItem(
            icon: Icons.headphones,
            label: 'Plays',
            count: _formatCount(song.playCount),
            color: theme.colorScheme.primary,
          ),

          // Likes
          if (song.likeCount > 0)
            _StatItem(
              icon: Icons.thumb_up,
              label: 'Likes',
              count: _formatCount(song.likeCount),
              color: theme.colorScheme.primary,
            ),

          // Dislikes
          if (song.dislikeCount > 0)
            _StatItem(
              icon: Icons.thumb_down,
              label: 'Dislikes',
              count: _formatCount(song.dislikeCount),
              color: Colors.red,
            ),

          // Comments
          if (song.commentCount > 0)
            _StatItem(
              icon: Icons.comment,
              label: 'Comments',
              count: _formatCount(song.commentCount),
              color: Colors.blue,
            ),

          // Shares
          if (song.shareCount > 0)
            _StatItem(
              icon: Icons.share,
              label: 'Shares',
              count: _formatCount(song.shareCount),
              color: Colors.green,
            ),

          // Token Reward
          _TokenRewardItem(
            tokenReward: song.tokenReward,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String count;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 32,
          color: color,
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

class _TokenRewardItem extends StatelessWidget {
  final int tokenReward;

  const _TokenRewardItem({
    required this.tokenReward,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const TokenIcon(size: 32, withShadow: true),
        const SizedBox(height: 8),
        Text(
          '+$tokenReward',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.tokenPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Reward',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
