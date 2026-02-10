/// API Configuration
class ApiConfig {
  // Base URL for API requests
  static const String baseUrl = 'http://localhost:9000';
  
  // Temporary token for development (should be replaced with actual auth)
  static const String tempToken = 'dev-token-placeholder';
  
  // API endpoints
  static const String songsEndpoint = '/api/songs';
  static const String userSongsEndpoint = '/api/songs/user';
  static const String uploadEndpoint = '/api/songs/upload';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
