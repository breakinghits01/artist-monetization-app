import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song_model.dart';
import '../services/song_api_service.dart';

// Song list state
final songListProvider =
    StateNotifierProvider<SongListNotifier, AsyncValue<List<SongModel>>>(
  (ref) => SongListNotifier(ref),
);

// Genres list provider
final genresProvider = FutureProvider<List<String>>((ref) async {
  final apiService = ref.read(songApiServiceProvider);
  return await apiService.getGenres();
});

// Selected genre filter
final selectedGenreProvider = StateProvider<String?>((ref) => null);

// Selected sort option
final selectedSortProvider = StateProvider<String>((ref) => 'createdAt');

// Search query
final searchQueryProvider = StateProvider<String>((ref) => '');

// Has more songs to load
final hasMoreSongsProvider = Provider<bool>((ref) {
  return ref.watch(songListProvider.notifier).hasMore;
});

class SongListNotifier extends StateNotifier<AsyncValue<List<SongModel>>> {
  final Ref _ref;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  SongListNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchSongs();
  }

  Future<void> fetchSongs({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    if (!_hasMore && !refresh) return;

    try {
      final apiService = _ref.read(songApiServiceProvider);
      final searchQuery = _ref.read(searchQueryProvider);
      final selectedGenre = _ref.read(selectedGenreProvider);
      final selectedSort = _ref.read(selectedSortProvider);

      final result = await apiService.discoverSongs(
        page: _currentPage,
        search: searchQuery.isNotEmpty ? searchQuery : null,
        genre: selectedGenre,
        sortBy: selectedSort,
      );

      final songs = result['songs'] as List<SongModel>;
      final pagination = result['pagination'] as Map<String, dynamic>;

      _hasMore = pagination['hasMore'] as bool;

      if (refresh || _currentPage == 1) {
        state = AsyncValue.data(songs);
      } else {
        state.whenData((current) {
          state = AsyncValue.data([...current, ...songs]);
        });
      }

      _currentPage++;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    await fetchSongs();
    _isLoadingMore = false;
  }

  void applyFilters() {
    _currentPage = 1;
    _hasMore = true;
    fetchSongs(refresh: true);
  }

  /// Update play count for a specific song in real-time
  void updateSongPlayCount(String songId, int newPlayCount) {
    state.whenData((songs) {
      final updatedSongs = songs.map((song) {
        if (song.id == songId) {
          return SongModel(
            id: song.id,
            title: song.title,
            duration: song.duration,
            price: song.price,
            coverArt: song.coverArt,
            audioUrl: song.audioUrl,
            exclusive: song.exclusive,
            genre: song.genre,
            description: song.description,
            playCount: newPlayCount, // Update with new count
            featured: song.featured,
            artist: song.artist,
            createdAt: song.createdAt,
          );
        }
        return song;
      }).toList();

      state = AsyncValue.data(updatedSongs);
      print('✅ Updated song $songId play count to $newPlayCount in discover list');
    });
  }

  // Expose hasMore state
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
}
