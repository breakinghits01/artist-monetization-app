import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/artist_model.dart';
import '../services/artist_api_service.dart';

/// Provider for discovering artists
final discoverArtistsProvider = FutureProvider.autoDispose
    .family<List<ArtistModel>, DiscoverArtistsParams>((ref, params) async {
  final apiService = ref.watch(artistApiServiceProvider);

  final result = await apiService.discoverArtists(
    page: params.page,
    limit: params.limit,
    search: params.search,
    genre: params.genre,
    sortBy: params.sortBy,
  );

  return result['artists'] as List<ArtistModel>;
});

/// Provider for featured artist on home screen
final featuredArtistProvider = FutureProvider<ArtistModel?>((ref) async {
  final apiService = ref.watch(artistApiServiceProvider);

  try {
    // Get top artist by follower count
    final result = await apiService.discoverArtists(
      page: 1,
      limit: 1,
      sortBy: 'followerCount',
    );

    final artists = result['artists'] as List<ArtistModel>;
    return artists.isNotEmpty ? artists.first : null;
  } catch (e) {
    print('⚠️ Error fetching featured artist: $e');
    return null;
  }
});

/// Provider for follow status
final followStatusProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, artistId) async {
  final apiService = ref.watch(artistApiServiceProvider);
  return await apiService.checkFollowStatus(artistId);
});

/// State notifier for managing follow/unfollow actions
final followActionProvider =
    StateNotifierProvider.family<FollowActionNotifier, AsyncValue<bool>, String>(
  (ref, artistId) => FollowActionNotifier(ref, artistId),
);

class FollowActionNotifier extends StateNotifier<AsyncValue<bool>> {
  final Ref _ref;
  final String _artistId;

  FollowActionNotifier(this._ref, this._artistId)
      : super(const AsyncValue.loading()) {
    _loadFollowStatus();
  }

  Future<void> _loadFollowStatus() async {
    try {
      final apiService = _ref.read(artistApiServiceProvider);
      final isFollowing = await apiService.checkFollowStatus(_artistId);
      state = AsyncValue.data(isFollowing);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleFollow() async {
    final currentState = state.value;
    if (currentState == null) return;

    // Optimistic update
    state = AsyncValue.data(!currentState);

    try {
      final apiService = _ref.read(artistApiServiceProvider);

      if (currentState) {
        await apiService.unfollowArtist(_artistId);
      } else {
        await apiService.followArtist(_artistId);
      }

      // Invalidate featured artist to refresh stats
      _ref.invalidate(featuredArtistProvider);
    } catch (e, stack) {
      // Revert on error
      state = AsyncValue.data(currentState);
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Parameters for artist discovery
class DiscoverArtistsParams {
  final int page;
  final int limit;
  final String? search;
  final String? genre;
  final String sortBy;

  const DiscoverArtistsParams({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.genre,
    this.sortBy = 'followerCount',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoverArtistsParams &&
          runtimeType == other.runtimeType &&
          page == other.page &&
          limit == other.limit &&
          search == other.search &&
          genre == other.genre &&
          sortBy == other.sortBy;

  @override
  int get hashCode =>
      page.hashCode ^
      limit.hashCode ^
      search.hashCode ^
      genre.hashCode ^
      sortBy.hashCode;
}
