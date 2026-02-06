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
}
