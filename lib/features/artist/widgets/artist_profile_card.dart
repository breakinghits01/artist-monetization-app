import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/artist_model.dart';
import '../providers/artist_provider.dart';

/// Artist profile card for home dashboard
class ArtistProfileCard extends ConsumerWidget {
  final ArtistModel artist;
  final VoidCallback? onTap;

  const ArtistProfileCard({
    super.key,
    required this.artist,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final followAction = ref.watch(followActionProvider(artist.id));

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.7),
                theme.colorScheme.secondary.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: artist.profilePicture != null &&
                                artist.profilePicture!.isNotEmpty
                            ? Image.network(
                                artist.profilePicture!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) =>
                                    _buildDefaultAvatar(),
                              )
                            : _buildDefaultAvatar(),
                      ),
                    ),
                    const Spacer(),
                    
                    // Artist Name
                    Text(
                      artist.username,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Stats
                    Text(
                      '${_formatCount(artist.followerCount)} followers • ${artist.songCount} songs',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Follow Button
                    followAction.when(
                      data: (isFollowing) => _buildFollowButton(
                        context,
                        theme,
                        isFollowing,
                        () => ref
                            .read(followActionProvider(artist.id).notifier)
                            .toggleFollow(),
                      ),
                      loading: () => _buildFollowButton(
                        context,
                        theme,
                        false,
                        null,
                        isLoading: true,
                      ),
                      error: (_, __) => _buildFollowButton(
                        context,
                        theme,
                        false,
                        null,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Library Icon (top right)
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.library_music,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: onTap,
                    tooltip: 'View Artist Library',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.white.withValues(alpha: 0.2),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  Widget _buildFollowButton(
    BuildContext context,
    ThemeData theme,
    bool isFollowing,
    VoidCallback? onPressed, {
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isFollowing
                ? Colors.white.withValues(alpha: 0.5)
                : theme.colorScheme.error,
            width: 1.5,
          ),
          backgroundColor: isFollowing
              ? Colors.transparent
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              )
            : Text(
                isFollowing ? 'Following' : 'Follow',
                style: TextStyle(
                  color: isFollowing
                      ? Colors.white.withValues(alpha: 0.9)
                      : theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
