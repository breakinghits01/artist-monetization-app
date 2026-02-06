import 'package:dio/dio.dart';
import '../services/dio_client.dart';
import '../constants/app_constants.dart';
import '../services/storage_service.dart';

/// Authentication API Service
/// 
/// Handles all authentication-related API calls including:
/// - User registration
/// - Login
/// - Token refresh
/// - Logout
/// - Password reset
/// - Email verification
class AuthApiService {
  final Dio _dio = DioClient.instance;
  final StorageService _storage = StorageService();

  /// Register a new user
  /// 
  /// Returns user data and tokens on success
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.registerEndpoint,
        data: {
          'username': username,
          'email': email,
          'password': password,
          'role': role,
        },
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        
        // Save tokens
        if (data['accessToken'] != null) {
          await _storage.saveAccessToken(data['accessToken']);
        }
        if (data['refreshToken'] != null) {
          await _storage.saveRefreshToken(data['refreshToken']);
        }

        return data;
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Registration failed',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: handleApiError(e),
        statusCode: e.response?.statusCode,
        data: e.response?.data,
      );
    }
  }

  /// Login existing user
  /// 
  /// Returns user data and tokens on success
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.loginEndpoint,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        
        // Save tokens
        if (data['accessToken'] != null) {
          await _storage.saveAccessToken(data['accessToken']);
        }
        if (data['refreshToken'] != null) {
          await _storage.saveRefreshToken(data['refreshToken']);
        }

        return data;
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Login failed',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: handleApiError(e),
        statusCode: e.response?.statusCode,
        data: e.response?.data,
      );
    }
  }

  /// Refresh access token using refresh token
  /// 
  /// Returns new access and refresh tokens
  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      
      if (refreshToken == null) {
        throw ApiException(
          message: 'No refresh token available',
          statusCode: 401,
        );
      }

      final response = await _dio.post(
        AppConstants.refreshTokenEndpoint,
        data: {
          'refreshToken': refreshToken,
        },
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        
        // Save new tokens
        if (data['accessToken'] != null) {
          await _storage.saveAccessToken(data['accessToken']);
        }
        if (data['refreshToken'] != null) {
          await _storage.saveRefreshToken(data['refreshToken']);
        }

        return data;
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Token refresh failed',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: handleApiError(e),
        statusCode: e.response?.statusCode,
        data: e.response?.data,
      );
    }
  }

  /// Logout current user
  /// 
  /// Clears tokens from storage and server
  Future<void> logout() async {
    try {
      await _dio.post(AppConstants.logoutEndpoint);
    } catch (e) {
      // Continue with logout even if API call fails
      print('Logout API error: $e');
    } finally {
      // Always clear local storage
      await _storage.clearAll();
    }
  }

  /// Request password reset email
  /// 
  /// Sends reset link to user's email
  Future<void> forgotPassword({required String email}) async {
    try {
      final response = await _dio.post(
        AppConstants.forgotPasswordEndpoint,
        data: {
          'email': email,
        },
      );

      if (response.data['success'] != true) {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to send reset email',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: handleApiError(e),
        statusCode: e.response?.statusCode,
        data: e.response?.data,
      );
    }
  }

  /// Reset password with token
  /// 
  /// Updates user password using reset token from email
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.resetPasswordEndpoint,
        data: {
          'token': token,
          'newPassword': newPassword,
        },
      );

      if (response.data['success'] != true) {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to reset password',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: handleApiError(e),
        statusCode: e.response?.statusCode,
        data: e.response?.data,
      );
    }
  }

  /// Verify user email with token
  /// 
  /// Verifies email address using token from verification email
  Future<void> verifyEmail({required String token}) async {
    try {
      final response = await _dio.get(
        AppConstants.verifyEmailEndpoint,
        queryParameters: {
          'token': token,
        },
      );

      if (response.data['success'] != true) {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to verify email',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: handleApiError(e),
        statusCode: e.response?.statusCode,
        data: e.response?.data,
      );
    }
  }

  /// Check if user is authenticated
  /// 
  /// Returns true if valid access token exists
  Future<bool> isAuthenticated() async {
    final accessToken = await _storage.getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }
}
