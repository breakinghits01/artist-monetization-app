import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../models/activity_model.dart';

final activityApiServiceProvider = Provider<ActivityApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return ActivityApiService(dio);
});

class ActivityApiService {
  final Dio _dio;
  final String _baseUrl = '/activity';

  ActivityApiService(this._dio);

  // Get activity feed (from followed artists)
  Future<Map<String, dynamic>> getActivityFeed({
    int page = 1,
    int limit = 20,
    ActivityType? type,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (type != null) {
        queryParams['type'] = type.value;
      }

      final response = await _dio.get(
        '$_baseUrl/feed',
        queryParameters: queryParams,
      );

      final activities = (response.data['data']['activities'] as List)
          .map((activity) => ActivityModel.fromJson(activity))
          .toList();

      return {
        'activities': activities,
        'pagination': response.data['data']['pagination'],
      };
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // Get user's own activities
  Future<Map<String, dynamic>> getUserActivities(String userId, {int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/user/$userId',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      final activities = (response.data['data']['activities'] as List)
          .map((activity) => ActivityModel.fromJson(activity))
          .toList();

      return {
        'activities': activities,
        'pagination': response.data['data']['pagination'],
      };
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // Delete an activity
  Future<void> deleteActivity(String activityId) async {
    try {
      await _dio.delete('$_baseUrl/$activityId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
