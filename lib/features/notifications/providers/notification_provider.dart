import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notification_api_service.dart';
import '../../auth/providers/auth_provider.dart';
import 'dart:async';

// Notification list state
final notificationListProvider =
    StateNotifierProvider<NotificationListNotifier, AsyncValue<List<NotificationModel>>>(
  (ref) => NotificationListNotifier(ref),
);

// Unread count state
final unreadCountProvider = StateNotifierProvider<UnreadCountNotifier, int>(
  (ref) => UnreadCountNotifier(ref),
);

class NotificationListNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final Ref _ref;
  int _currentPage = 1;
  bool _hasMore = true;
  Timer? _refreshTimer;
  bool _isTimerActive = false;

  NotificationListNotifier(this._ref) : super(const AsyncValue.data([])) {
    // Only fetch if user is authenticated
    final authState = _ref.read(authProvider);
    if (authState.isAuthenticated) {
      fetchNotifications();
      _startAutoRefresh();
    }
  }

  Future<void> fetchNotifications({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    try {
      final apiService = _ref.read(notificationApiServiceProvider);
      final result = await apiService.getNotifications(page: _currentPage);

      final notifications = result['notifications'] as List<NotificationModel>;
      final pagination = result['pagination'] as Map<String, dynamic>;

      _hasMore = pagination['hasMore'] as bool;

      if (refresh || _currentPage == 1) {
        state = AsyncValue.data(notifications);
      } else {
        state.whenData((current) {
          state = AsyncValue.data([...current, ...notifications]);
        });
      }

      _currentPage++;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    await fetchNotifications();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final apiService = _ref.read(notificationApiServiceProvider);
      final updatedNotification = await apiService.markAsRead(notificationId);

      state.whenData((notifications) {
        final updatedList = notifications.map((n) {
          return n.id == notificationId ? updatedNotification : n;
        }).toList();
        state = AsyncValue.data(updatedList);
      });

      // Update unread count
      _ref.read(unreadCountProvider.notifier).fetchUnreadCount();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final apiService = _ref.read(notificationApiServiceProvider);
      await apiService.markAllAsRead();

      state.whenData((notifications) {
        final updatedList = notifications.map((n) {
          return NotificationModel(
            id: n.id,
            userId: n.userId,
            type: n.type,
            sender: n.sender,
            song: n.song,
            message: n.message,
            metadata: n.metadata,
            isRead: true,
            createdAt: n.createdAt,
          );
        }).toList();
        state = AsyncValue.data(updatedList);
      });

      // Update unread count
      _ref.read(unreadCountProvider.notifier).fetchUnreadCount();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final apiService = _ref.read(notificationApiServiceProvider);
      await apiService.deleteNotification(notificationId);

      state.whenData((notifications) {
        final updatedList = notifications.where((n) => n.id != notificationId).toList();
        state = AsyncValue.data(updatedList);
      });

      // Update unread count
      _ref.read(unreadCountProvider.notifier).fetchUnreadCount();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _startAutoRefresh() {
    if (_isTimerActive) return;
    _isTimerActive = true;
    
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchNotifications(refresh: true);
      _ref.read(unreadCountProvider.notifier).fetchUnreadCount();
    });
  }
  
  /// Pause auto-refresh (call when app goes to background)
  void pauseAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _isTimerActive = false;
  }
  
  /// Resume auto-refresh (call when app comes to foreground)
  void resumeAutoRefresh() {
    if (!_isTimerActive) {
      _startAutoRefresh();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

class UnreadCountNotifier extends StateNotifier<int> {
  final Ref _ref;

  UnreadCountNotifier(this._ref) : super(0) {
    // Only fetch if user is authenticated
    final authState = _ref.read(authProvider);
    if (authState.isAuthenticated) {
      fetchUnreadCount();
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final apiService = _ref.read(notificationApiServiceProvider);
      final count = await apiService.getUnreadCount();
      state = count;
    } catch (e) {
      // Silent fail for unread count
      state = 0;
    }
  }

  void decrementCount() {
    if (state > 0) {
      state = state - 1;
    }
  }

  void resetCount() {
    state = 0;
  }
}
