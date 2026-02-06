import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity_model.dart';
import '../services/activity_api_service.dart';

// Activity feed filter provider
final activityFilterProvider = StateProvider<ActivityType?>((ref) => null);

// Activity feed provider
final activityFeedProvider =
    StateNotifierProvider<ActivityFeedNotifier, AsyncValue<List<ActivityModel>>>(
  (ref) => ActivityFeedNotifier(ref),
);

class ActivityFeedNotifier extends StateNotifier<AsyncValue<List<ActivityModel>>> {
  final Ref _ref;
  int _currentPage = 1;
  bool _hasMore = true;

  ActivityFeedNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchActivities();
  }

  Future<void> fetchActivities({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    if (!_hasMore && !refresh) return;

    try {
      final apiService = _ref.read(activityApiServiceProvider);
      final filterType = _ref.read(activityFilterProvider);

      final result = await apiService.getActivityFeed(
        page: _currentPage,
        type: filterType,
      );

      final activities = result['activities'] as List<ActivityModel>;
      final pagination = result['pagination'] as Map<String, dynamic>;

      _hasMore = pagination['hasMore'] as bool;

      if (refresh || _currentPage == 1) {
        state = AsyncValue.data(activities);
      } else {
        state.whenData((current) {
          state = AsyncValue.data([...current, ...activities]);
        });
      }

      _currentPage++;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadMore() async {
    if (_hasMore && !state.isLoading) {
      await fetchActivities();
    }
  }

  Future<void> refresh() async {
    await fetchActivities(refresh: true);
  }

  Future<void> deleteActivity(String activityId) async {
    try {
      final apiService = _ref.read(activityApiServiceProvider);
      await apiService.deleteActivity(activityId);

      // Remove from current list
      state.whenData((activities) {
        final updated = activities.where((a) => a.id != activityId).toList();
        state = AsyncValue.data(updated);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// User activities provider (for specific user)
final userActivitiesProvider =
    FutureProvider.family<List<ActivityModel>, String>((ref, userId) async {
  final apiService = ref.watch(activityApiServiceProvider);
  final result = await apiService.getUserActivities(userId);
  return result['activities'] as List<ActivityModel>;
});
