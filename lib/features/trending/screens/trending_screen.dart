import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../player/models/song_model.dart';
import '../../player/providers/audio_player_provider.dart';
import '../../player/widgets/audio_wave_indicator.dart';
import '../providers/trending_provider.dart';
import '../../../shared/widgets/token_icon.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../engagement/providers/like_provider.dart';
import '../../engagement/widgets/comments_bottom_sheet.dart';
import '../../engagement/widgets/share_bottom_sheet.dart';

/// Trending songs screen with rankings
class TrendingScreen extends ConsumerStatefulWidget {
  const TrendingScreen({super.key});

  @override
  ConsumerState<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends ConsumerState<TrendingScreen> 
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trendingSongsAsync = ref.watch(trendingSongsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(trendingSongsProvider.notifier).refresh();
        },
        child: Stack(
        children: [
          CustomScrollView(
          key: const PageStorageKey<String>('trending_scroll'),
          controller: _scrollController,
          slivers: [
            // Animated shrinking banner with pinned title
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              automaticallyImplyLeading: false,
              leading: context.canPop()
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                      tooltip: 'Back',
                    )
                  : null,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Trending Now',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.9),
                        theme.colorScheme.secondary.withValues(alpha: 0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative elements
                      Positioned(
                        right: -50,
                        top: -50,
                        child: Icon(
                          Icons.emoji_events,
                          size: 200,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        bottom: 60,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '🔥 HOT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Content
          trendingSongsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load trending songs',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            data: (songs) {
              if (songs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_note_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No trending songs yet',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.only(bottom: 16),
                sliver: SliverList.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    final rank = index + 1;
                    
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0, 0.3 * (index % 5)),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            (index % 5) * 0.1,
                            0.5 + (index % 5) * 0.1,
                            curve: Curves.easeOut,
                          ),
                        )),
                        child: _TrendingSongTile(
                          song: song,
                          rank: rank,
                          allSongs: songs,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          
          // Bottom padding to ensure proper scroll behavior
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
        ],
      ),
      ),
    );
  }
}

/// Individual trending song tile with ranking
class _TrendingSongTile extends ConsumerStatefulWidget {
  final SongModel song;
  final int rank;
  final List<SongModel> allSongs;

  const _TrendingSongTile({
    required this.song,
    required this.rank,
    required this.allSongs,
  });

  @override
  ConsumerState<_TrendingSongTile> createState() => _TrendingSongTileState();
}

class _TrendingSongTileState extends ConsumerState<_TrendingSongTile> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final rank = widget.rank;
    final allSongs = widget.allSongs;
    final theme = Theme.of(context);
    final currentSong = ref.watch(currentSongProvider);
    final playerState = ref.watch(audioPlayerProvider);
    final isCurrentSong = currentSong?.id == song.id;
    final isPlaying = isCurrentSong && playerState.isPlaying;

    // Medal for top 3
    String? medal;
    Color? rankColor;
    if (rank == 1) {
      medal = '🥇';
      rankColor = const Color(0xFFFFD700); // Gold
    } else if (rank == 2) {
      medal = '🥈';
      rankColor = const Color(0xFFC0C0C0); // Silver
    } else if (rank == 3) {
      medal = '🥉';
      rankColor = const Color(0xFFCD7F32); // Bronze
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: isCurrentSong ? 8 : 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Rank number or medal
            SizedBox(
              width: 50,
              child: medal != null
                  ? Text(
                      medal,
                      style: const TextStyle(fontSize: 32),
                      textAlign: TextAlign.center,
                    )
                  : Text(
                      '$rank',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
            const SizedBox(width: 12),

            // Album art - tap to play/pause
            InkWell(
              onTap: () {
                if (isCurrentSong) {
                  ref.read(audioPlayerProvider.notifier).playPause();
                } else {
                  ref.read(audioPlayerProvider.notifier).playSongWithQueue(song, allSongs);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: rankColor?.withValues(alpha: 0.3) ?? 
                                 theme.colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: song.albumArt != null
                          ? CachedNetworkImage(
                              imageUrl: song.albumArt!,
                              fit: BoxFit.cover,
                              memCacheHeight: 150,
                              memCacheWidth: 150,
                              placeholder: (context, url) => Container(
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.music_note,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.music_note,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                ),
                              ),
                            )
                          : Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.music_note,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                            ),
                    ),
                  ),
                  if (isCurrentSong)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: isPlaying
                              ? AudioWaveIndicator(
                                  isPlaying: true,
                                  color: Colors.white,
                                  size: 32,
                                )
                              : const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 32,
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Song info - tap to navigate to detail screen
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Navigate to song detail screen - push to maintain navigation stack
                  context.push('/song/${song.id}', extra: song);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MouseRegion(
                      onEnter: (_) => setState(() => _isHovering = true),
                      onExit: (_) => setState(() => _isHovering = false),
                      cursor: SystemMouseCursors.click,
                      child: Text(
                        song.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isCurrentSong ? theme.colorScheme.primary : null,
                          decoration: _isHovering ? TextDecoration.underline : null,
                          decorationColor: isCurrentSong ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // First row: Genre/Category + Token
                    Row(
                      children: [
                        Text(
                          song.genre ?? 'Unknown',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const TokenIcon(size: 14, withShadow: false),
                        const SizedBox(width: 4),
                        Text(
                          '+${song.tokenReward}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.tokenPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (song.isPremium) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'PREMIUM',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Second row: Play count + Like + Dislike + Comment + Share
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Play count
                        if (song.playCount > 0) ...[
                          Icon(
                            Icons.headphones,
                            size: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${song.playCount}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        // Like button with rounded background and animation
                        Consumer(
                          builder: (context, ref, child) {
                            final likeState = ref.watch(likeProvider(song.id));
                            
                            return AnimatedScale(
                              scale: likeState.isLoading ? 0.9 : 1.0,
                              duration: const Duration(milliseconds: 150),
                              child: InkWell(
                                onTap: likeState.isLoading
                                    ? null
                                    : () {
                                        ref.read(likeProvider(song.id).notifier).toggleLike();
                                      },
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: likeState.isLiked
                                        ? theme.colorScheme.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: likeState.isLiked
                                        ? Border.all(
                                            color: theme.colorScheme.primary,
                                            width: 1,
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.thumb_up_outlined,
                                        size: 14,
                                        color: likeState.isLiked
                                            ? Colors.white
                                            : theme.colorScheme.onSurface.withOpacity(0.5),
                                      ),
                                      if (likeState.likeCount > 0) ...[
                                        const SizedBox(width: 4),
                                        Text(
                                          '${likeState.likeCount}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: likeState.isLiked
                                                ? Colors.white
                                                : theme.colorScheme.onSurface.withOpacity(0.5),
                                            fontWeight: likeState.isLiked
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        // Dislike button with rounded background and animation
                        Consumer(
                          builder: (context, ref, child) {
                            final likeState = ref.watch(likeProvider(song.id));
                            
                            return AnimatedScale(
                              scale: likeState.isLoading ? 0.9 : 1.0,
                              duration: const Duration(milliseconds: 150),
                              child: InkWell(
                                onTap: likeState.isLoading
                                    ? null
                                    : () {
                                        ref.read(likeProvider(song.id).notifier).toggleDislike();
                                      },
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: likeState.isDisliked
                                        ? Colors.red.shade400
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: likeState.isDisliked
                                        ? Border.all(
                                            color: Colors.red.shade400,
                                            width: 1,
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.thumb_down_outlined,
                                        size: 14,
                                        color: likeState.isDisliked
                                            ? Colors.white
                                            : theme.colorScheme.onSurface.withOpacity(0.5),
                                      ),
                                      if (likeState.dislikeCount > 0) ...[
                                        const SizedBox(width: 4),
                                        Text(
                                          '${likeState.dislikeCount}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: likeState.isDisliked
                                                ? Colors.white
                                                : theme.colorScheme.onSurface.withOpacity(0.5),
                                            fontWeight: likeState.isDisliked
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        // Comment icon with total count (including replies)
                        InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => CommentsBottomSheet(song: song),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.comment_outlined,
                                  size: 14,
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                                if (song.commentCount > 0) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '${song.commentCount}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Share icon with consistent padding
                        InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (context) => ShareBottomSheet(song: song),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.share_outlined,
                                  size: 14,
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                                if (song.shareCount > 0) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '${song.shareCount}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Play button
            IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: rankColor ?? theme.colorScheme.primary,
                  size: 40,
                ),
                onPressed: () {
                  if (isCurrentSong) {
                    ref.read(audioPlayerProvider.notifier).playPause();
                  } else {
                    ref.read(audioPlayerProvider.notifier).playSongWithQueue(song, allSongs);
                  }
                },
              ),
            ], // End of Row children
          ), // End of Padding child (Row)
        ), // End of Card child (Padding)
    ); // End of return Card
  }
}
