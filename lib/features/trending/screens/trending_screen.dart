import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../player/models/song_model.dart';
import '../../player/providers/audio_player_provider.dart';
import '../../player/widgets/audio_wave_indicator.dart';
import '../../player/widgets/player_wrapper.dart';
import '../../player/widgets/mini_player.dart';
import '../providers/trending_provider.dart';
import '../../../shared/widgets/token_icon.dart';
import '../../../core/theme/app_colors_extension.dart';

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
    final currentSong = ref.watch(currentSongProvider);

    return PlayerWrapper(
      child: Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
            // Hero Header
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Trending Now',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Hero(
                tag: 'trending_card',
                child: Container(
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
                          Icons.trending_up,
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
          
          // Add bottom padding for mini player
          if (currentSong != null)
            const SliverToBoxAdapter(
              child: SizedBox(height: 90),
            ),
        ],
      ),
      
      // Mini player at bottom
      if (currentSong != null)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            child: const MiniPlayer(),
          ),
        ),
        ],
      ),
      ),
    );
  }
}

/// Individual trending song tile with ranking
class _TrendingSongTile extends ConsumerWidget {
  final SongModel song;
  final int rank;
  final List<SongModel> allSongs;

  const _TrendingSongTile({
    required this.song,
    required this.rank,
    required this.allSongs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      child: InkWell(
        onTap: () {
          if (isCurrentSong) {
            ref.read(audioPlayerProvider.notifier).playPause();
          } else {
            ref.read(audioPlayerProvider.notifier).playSongWithQueue(song, allSongs);
          }
        },
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

              // Album art
              Stack(
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
              const SizedBox(width: 12),

              // Song info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isCurrentSong ? theme.colorScheme.primary : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                    Row(
                      children: [
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
                  ],
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
            ],
          ),
        ),
      ),
    );
  }
}
