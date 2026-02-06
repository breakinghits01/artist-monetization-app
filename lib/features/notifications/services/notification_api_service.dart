import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../models/notification_model.dart';

final notificationApiServiceProvider = Provider<NotificationApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return NotificationApiService(dio);
});

class NotificationApiService {
  final Dio _dio;
  static const String _baseUrl = '/notifications';

  NotificationApiService(this._dio);

  /// Get all notifications with pagination
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (unreadOnly != null) 'unreadOnly': unreadOnly.toString(),
      };

      final response = await _dio.get(
        _baseUrl,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final notifications = (data['notifications'] as List)
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        return {
          'notifications': notifications,
          'pagination': data['pagination'],
        };
      }

      throw ApiException(message: 'Failed to fetch notifications');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get('$_baseUrl/unread-count');

      if (response.statusCode == 200) {
        return response.data['data']['count'] as int;
      }

      throw ApiException(message: 'Failed to fetch unread count');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Mark a notification as read
  Future<NotificationModel> markAsRead(String notificationId) async {
    try {
      final response = await _dio.patch('$_baseUrl/$notificationId/read');

      if (response.statusCode == 200) {
        return NotificationModel.fromJson(response.data['data']['notification']);
      }

      throw ApiException(message: 'Failed to mark notification as read');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Mark all notifications as read
  Future<int> markAllAsRead() async {
    try {
      final response = await _dio.patch('$_baseUrl/read-all');

      if (response.statusCode == 200) {
        return response.data['data']['modifiedCount'] as int;
      }

      throw ApiException(message: 'Failed to mark all as read');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final response = await _dio.delete('$_baseUrl/$notificationId');

      if (response.statusCode != 200) {
        throw ApiException(message: 'Failed to delete notification');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
