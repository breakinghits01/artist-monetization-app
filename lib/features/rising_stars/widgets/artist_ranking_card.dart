import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/artist_ranking_model.dart';
import 'rank_badge.dart';

/// Artist ranking card with score breakdown
class ArtistRankingCard extends StatelessWidget {
  final ArtistRanking artist;
  final int rank;

  const ArtistRankingCard({
    super.key,
    required this.artist,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          // Navigate to artist profile
          context.push('/profile/${artist.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Rank badge
              RankBadge(rank: rank),
              
              const SizedBox(width: 16),
              
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                backgroundImage: artist.avatar != null
                    ? NetworkImage(artist.avatar!)
                    : null,
                child: artist.avatar == null
                    ? Icon(
                        Icons.person,
                        size: 30,
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
              
              const SizedBox(width: 16),
              
              // Artist info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username
                    Text(
                      artist.username,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Stats row
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${artist.followerCount}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        Icon(
                          Icons.music_note_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${artist.songCount}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Rising score
              Column(
                children: [
                  Text(
                    artist.risingScore.toStringAsFixed(1),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    'score',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildScoreBreakdown(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        if (artist.recentLikesCount > 0)
          _buildStatChip(
            context,
            Icons.favorite_outline,
            artist.recentLikesCount,
            Colors.pink,
          ),
        if (artist.recentCommentsCount > 0)
          _buildStatChip(
            context,
            Icons.comment_outlined,
            artist.recentCommentsCount,
            Colors.orange,
          ),
        if (artist.recentSharesCount > 0)
          _buildStatChip(
            context,
            Icons.share_outlined,
            artist.recentSharesCount,
            Colors.green,
          ),
      ],
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    IconData icon,
    int count,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
