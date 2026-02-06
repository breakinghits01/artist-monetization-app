import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import './storage_service.dart';

/// Dio HTTP Client Configuration
/// 
/// This class sets up the Dio client with proper configuration
/// for API communication, including interceptors for logging,
/// error handling, and token refresh.
class DioClient {
  static Dio? _instance;

  /// Get singleton instance of configured Dio client
  static Dio get instance {
    if (_instance == null) {
      _instance = Dio(_baseOptions);
      _setupInterceptors(_instance!);
    }
    return _instance!;
  }

  /// Base options for Dio client
  static BaseOptions get _baseOptions => BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        sendTimeout: AppConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true', // Skip ngrok warning page
        },
      );

  /// Setup interceptors for logging, auth, and error handling
  static void _setupInterceptors(Dio dio) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add access token to headers if available
          final storage = StorageService();
          final token = await storage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Log request
          print('REQUEST[${options.method}] => PATH: ${options.path}');
          print('HEADERS: ${options.headers}');
          if (options.data != null) {
            print('DATA: ${options.data}');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Log response
          print('RESPONSE[${response.statusCode}] => DATA: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          // Log error
          print('ERROR[${error.response?.statusCode}] => DATA: ${error.response?.data}');
          print('MESSAGE: ${error.message}');

          // Handle 401 Unauthorized - Token expired
          if (error.response?.statusCode == 401) {
            // TODO: Implement token refresh logic
            // try {
            //   final storage = StorageService();
            //   final refreshToken = await storage.getRefreshToken();
            //   
            //   if (refreshToken != null) {
            //     // Call refresh token endpoint
            //     final response = await dio.post(
            //       AppConstants.refreshTokenEndpoint,
            //       data: {'refreshToken': refreshToken},
            //     );
            //     
            //     // Save new tokens
            //     final newAccessToken = response.data['accessToken'];
            //     final newRefreshToken = response.data['refreshToken'];
            //     await storage.saveAccessToken(newAccessToken);
            //     await storage.saveRefreshToken(newRefreshToken);
            //     
            //     // Retry the original request with new token
            //     error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            //     final retryResponse = await dio.request(
            //       error.requestOptions.path,
            //       options: Options(
            //         method: error.requestOptions.method,
            //         headers: error.requestOptions.headers,
            //       ),
            //       data: error.requestOptions.data,
            //       queryParameters: error.requestOptions.queryParameters,
            //     );
            //     
            //     return handler.resolve(retryResponse);
            //   }
            // } catch (e) {
            //   // Refresh failed - logout user
            //   await storage.clearAll();
            //   // Navigate to login
            //   // ref.read(authProvider.notifier).logout();
            // }
          }

          return handler.next(error);
        },
      ),
    );
  }

  /// Reset client instance (useful for testing)
  static void reset() {
    _instance?.close();
    _instance = null;
  }
}

/// API Exception Types
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// Handle API errors and convert to user-friendly messages
String handleApiError(dynamic error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'];

        switch (statusCode) {
          case 400:
            return message ?? 'Invalid request. Please check your input.';
          case 401:
            return 'Unauthorized. Please login again.';
          case 403:
            return 'Access forbidden.';
          case 404:
            return 'Resource not found.';
          case 422:
            return message ?? AppConstants.validationErrorMessage;
          case 500:
            return AppConstants.serverErrorMessage;
          default:
            return message ?? 'An error occurred. Please try again.';
        }

      case DioExceptionType.cancel:
        return 'Request cancelled.';

      case DioExceptionType.unknown:
        if (error.error.toString().contains('SocketException')) {
          return AppConstants.networkErrorMessage;
        }
        return AppConstants.unknownErrorMessage;

      default:
        return AppConstants.unknownErrorMessage;
    }
  }

  return error.toString();
}
