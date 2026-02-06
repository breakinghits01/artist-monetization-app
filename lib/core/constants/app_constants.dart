import 'package:flutter/foundation.dart' show kIsWeb;

/// Application Constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Artist Monetization';
  static const String appVersion = '1.0.0';

  // API Configuration
  // ngrok tunnel URL - works from ANYWHERE (not just local network)
  static const String tunnelBaseUrl = 'https://caryl-exertive-treva.ngrok-free.dev';
  
  // Both web and mobile use the SAME ngrok tunnel
  // Flutter web: https://caryl-exertive-treva.ngrok-free.dev/
  // API: https://caryl-exertive-treva.ngrok-free.dev/api/v1
  static String get baseUrl => tunnelBaseUrl;
  
  static const String apiVersion = '/api/v1';
  static String get apiBaseUrl => '$baseUrl$apiVersion';

  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String logoutEndpoint = '/auth/logout';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  static const String verifyEmailEndpoint = '/auth/verify-email';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String themeModeKey = 'theme_mode';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;

  // Routes
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String resetPasswordRoute = '/reset-password';
  static const String homeRoute = '/home';
  static const String profileRoute = '/profile';
  static const String settingsRoute = '/settings';
  static const String treasureChestRoute = '/treasure-chest';
  static const String myMusicRoute = '/my-music';
  static const String purchasesRoute = '/purchases';

  // Error Messages
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String serverErrorMessage = 'Server error. Please try again later.';
  static const String unknownErrorMessage = 'An unknown error occurred.';
  static const String unauthorizedErrorMessage = 'Unauthorized. Please login again.';
  static const String validationErrorMessage = 'Please check your input and try again.';

  // Success Messages
  static const String loginSuccessMessage = 'Login successful!';
  static const String registerSuccessMessage = 'Registration successful!';
  static const String logoutSuccessMessage = 'Logout successful!';
  static const String passwordResetEmailSentMessage = 'Password reset email sent!';
  static const String passwordResetSuccessMessage = 'Password reset successful!';

  // Regex Patterns
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp usernameRegex = RegExp(
    r'^[a-zA-Z0-9_]+$',
  );

  // Password must contain at least one uppercase, lowercase, number, and special character
  static final RegExp strongPasswordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])[A-Za-z\d@$!%*?&#]+$',
  );
}
