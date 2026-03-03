import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../player/models/song_model.dart';
import '../../discover/services/song_api_service.dart';
import '../screens/song_detail_screen.dart';

/// Provider to fetch song by ID for deep linking
/// Returns player SongModel format
final songByIdProvider = FutureProvider.family<SongModel, String>((ref, songId) async {
  final apiService = ref.watch(songApiServiceProvider);
  final discoverSong = await apiService.getSongById(songId);
  
  // Convert discover model to player model
  return SongModel(
    id: discoverSong.id,
    title: discoverSong.title,
    artist: discoverSong.artist?.username ?? 'Unknown Artist',
    artistId: discoverSong.artist?.id ?? '',
    albumArt: discoverSong.coverArt,
    audioUrl: discoverSong.audioUrl,
    duration: Duration(seconds: discoverSong.duration),
    tokenReward: (discoverSong.price * 10).toInt(), // Convert price to tokens
    genre: discoverSong.genre,
    isPremium: discoverSong.exclusive,
    playCount: discoverSong.playCount,
    // Engagement metrics will be loaded by providers when screen opens
    likeCount: 0,
    dislikeCount: 0,
    commentCount: 0,
    shareCount: 0,
  );
});

/// Wrapper widget that handles loading song data from API if not provided
/// This enables deep linking - users can share song URLs and they'll work
class SongDetailWrapper extends ConsumerWidget {
  final String songId;
  final SongModel? initialSong;

  const SongDetailWrapper({
    super.key,
    required this.songId,
    this.initialSong,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If we have initial song data (navigation from app), use it immediately
    if (initialSong != null) {
      return SongDetailScreen(song: initialSong!);
    }

    // Otherwise, fetch from API (deep link / shared URL / page refresh)
    final songAsync = ref.watch(songByIdProvider(songId));

    return songAsync.when(
      data: (song) => SongDetailScreen(song: song),
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Loading...'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Error'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load song',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
