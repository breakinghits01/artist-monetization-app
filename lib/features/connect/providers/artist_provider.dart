import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/artist_model.dart';
import '../services/artist_api_service.dart';
import '../../auth/providers/auth_provider.dart';

// Selected sort option for artist discovery
final selectedArtistSortProvider = StateProvider<String>((ref) => 'followerCount');

// Search query for artist discovery
final artistSearchQueryProvider = StateProvider<String>((ref) => '');

// Selected genre filter for artist discovery
final selectedArtistGenreProvider = StateProvider<String?>((ref) => null);

// Artist list state
final artistListProvider =
    StateNotifierProvider<ArtistListNotifier, AsyncValue<List<ArtistModel>>>(
  (ref) => ArtistListNotifier(ref),
);

class ArtistListNotifier extends StateNotifier<AsyncValue<List<ArtistModel>>> {
  final Ref _ref;
  int _currentPage = 1;
  bool _hasMore = true;

  ArtistListNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchArtists();
  }

  Future<void> fetchArtists({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    if (!_hasMore && !refresh) return;

    try {
      final apiService = _ref.read(artistApiServiceProvider);
      final sortBy = _ref.read(selectedArtistSortProvider);
      final search = _ref.read(artistSearchQueryProvider);
      final genre = _ref.read(selectedArtistGenreProvider);
      final authState = _ref.read(authProvider);
      final currentUserId = authState.user?['_id'] as String?;

      final result = await apiService.discoverArtists(
        page: _currentPage,
        sortBy: sortBy,
        search: search.isEmpty ? null : search,
        genre: genre,
      );

      var artists = result['artists'] as List<ArtistModel>;
      final pagination = result['pagination'] as Map<String, dynamic>;

      // Filter out current user from the list (frontend safety check)
      if (currentUserId != null) {
        artists = artists.where((artist) => artist.id != currentUserId).toList();
      }

      _hasMore = pagination['hasMore'] as bool;

      if (refresh || _currentPage == 1) {
        state = AsyncValue.data(artists);
      } else {
        state.whenData((current) {
          state = AsyncValue.data([...current, ...artists]);
        });
      }

      _currentPage++;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadMore() async {
    if (_hasMore && !state.isLoading) {
      await fetchArtists();
    }
  }

  Future<void> refresh() async {
    await fetchArtists(refresh: true);
  }
}

// Artist profile provider (for specific artist)
final artistProfileProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, artistId) async {
  final apiService = ref.watch(artistApiServiceProvider);
  return await apiService.getArtistProfile(artistId);
});

// Current user profile provider
final currentUserProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.watch(artistApiServiceProvider);
  return await apiService.getCurrentUserProfile();
});
