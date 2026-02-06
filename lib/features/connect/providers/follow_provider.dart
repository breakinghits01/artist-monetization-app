import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/artist_model.dart';
import '../services/follow_api_service.dart';

// Follow status map (artistId -> isFollowing)
final followStatusMapProvider = StateProvider<Map<String, bool>>((ref) => {});

// Following list provider (artists current user follows)
final followingListProvider =
    StateNotifierProvider<FollowingListNotifier, AsyncValue<List<ArtistModel>>>(
  (ref) => FollowingListNotifier(ref),
);

class FollowingListNotifier extends StateNotifier<AsyncValue<List<ArtistModel>>> {
  final Ref _ref;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _userId;

  FollowingListNotifier(this._ref) : super(const AsyncValue.data([]));

  void setUserId(String userId) {
    _userId = userId;
    fetchFollowing(refresh: true);
  }

  Future<void> fetchFollowing({bool refresh = false}) async {
    if (_userId == null) return;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    if (!_hasMore && !refresh) return;

    try {
      final apiService = _ref.read(followApiServiceProvider);

      final result = await apiService.getFollowing(
        _userId!,
        page: _currentPage,
      );

      final following = result['following'] as List<ArtistModel>;
      final pagination = result['pagination'] as Map<String, dynamic>;

      _hasMore = pagination['hasMore'] as bool;

      if (refresh || _currentPage == 1) {
        state = AsyncValue.data(following);
      } else {
        state.whenData((current) {
          state = AsyncValue.data([...current, ...following]);
        });
      }

      _currentPage++;

      // Update follow status map
      final statusMap = _ref.read(followStatusMapProvider.notifier);
      for (final artist in following) {
        statusMap.state = {...statusMap.state, artist.id: true};
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadMore() async {
    if (_hasMore && !state.isLoading) {
      await fetchFollowing();
    }
  }
}

// Follow/Unfollow action provider
final followActionProvider = Provider<FollowActions>((ref) => FollowActions(ref));

class FollowActions {
  final Ref _ref;

  FollowActions(this._ref);

  Future<void> followArtist(String artistId) async {
    try {
      final apiService = _ref.read(followApiServiceProvider);
      await apiService.followArtist(artistId);

      // Update follow status map
      final statusMap = _ref.read(followStatusMapProvider.notifier);
      statusMap.state = {...statusMap.state, artistId: true};

      // Refresh following list if loaded
      _ref.read(followingListProvider.notifier).fetchFollowing(refresh: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unfollowArtist(String artistId) async {
    try {
      final apiService = _ref.read(followApiServiceProvider);
      await apiService.unfollowArtist(artistId);

      // Update follow status map
      final statusMap = _ref.read(followStatusMapProvider.notifier);
      statusMap.state = {...statusMap.state, artistId: false};

      // Refresh following list if loaded
      _ref.read(followingListProvider.notifier).fetchFollowing(refresh: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> checkFollowStatus(String artistId) async {
    try {
      final apiService = _ref.read(followApiServiceProvider);
      final isFollowing = await apiService.checkFollowStatus(artistId);

      // Update status map
      final statusMap = _ref.read(followStatusMapProvider.notifier);
      statusMap.state = {...statusMap.state, artistId: isFollowing};

      return isFollowing;
    } catch (e) {
      return false;
    }
  }
}

// Check follow status provider (for specific artist)
final artistFollowStatusProvider =
    FutureProvider.family<bool, String>((ref, artistId) async {
  // Check if status is already in map
  final statusMap = ref.watch(followStatusMapProvider);
  if (statusMap.containsKey(artistId)) {
    return statusMap[artistId]!;
  }

  // Fetch from API
  final apiService = ref.watch(followApiServiceProvider);
  final isFollowing = await apiService.checkFollowStatus(artistId);

  // Update map
  final mapNotifier = ref.read(followStatusMapProvider.notifier);
  mapNotifier.state = {...mapNotifier.state, artistId: isFollowing};

  return isFollowing;
});
