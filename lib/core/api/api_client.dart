import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/dio_client.dart';

/// Provider for Dio instance
final dioProvider = Provider<Dio>((ref) {
  return DioClient.instance;
});
