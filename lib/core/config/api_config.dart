/// API Configuration
class ApiConfig {
  // Base URL for API requests
  // Use full ngrok URL for global access from any device/location
  static const String baseUrl = 'https://caryl-exertive-treva.ngrok-free.dev';
  
  // API version
  static const String apiVersion = 'v1';
  
  // Deprecated: Use actual auth token from StorageService instead
  @deprecated
  static const String tempToken = 'deprecated-use-auth-token';
  
  // API endpoints (with version prefix)
  static const String songsEndpoint = '/api/$apiVersion/songs';
  static const String userSongsEndpoint = '/api/$apiVersion/songs/user';
  static const String uploadEndpoint = '/api/$apiVersion/songs/upload';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
