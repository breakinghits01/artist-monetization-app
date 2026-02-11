/// API Configuration
class ApiConfig {
  // Base URL for API requests (backend is on port 3000)
  static const String baseUrl = 'http://localhost:3000';
  
  // API version
  static const String apiVersion = 'v1';
  
  // Temporary token for development (should be replaced with actual auth)
  static const String tempToken = 'dev-token-placeholder';
  
  // API endpoints (with version prefix)
  static const String songsEndpoint = '/api/$apiVersion/songs';
  static const String userSongsEndpoint = '/api/$apiVersion/songs/user';
  static const String uploadEndpoint = '/api/$apiVersion/songs/upload';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
