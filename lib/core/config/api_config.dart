/// API Configuration
class ApiConfig {
  // Base URL for API requests
  // Empty string means use same domain as web app (works with ngrok)
  // For local development, this will use http://localhost:9000/api
  // For production/ngrok, this will use the ngrok domain/api
  static const String baseUrl = '';
  
  // API version
  static const String apiVersion = 'v1';
  
  // Temporary token for development (should be replaced with actual auth)
  static const String tempToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2OTgyYmRhMWI3YTczNTcwZGE2OTBkYjkiLCJ1c2VybmFtZSI6ImRla3pibGFzdGVyIiwiaWF0IjoxNzM2OTE2NzIyLCJleHAiOjE3Mzk1MDg3MjJ9.lZW4-_ZMiCKpEZjzz1kTvEI1d8Cso1XWWuqLu3Y6dAU';
  
  // API endpoints (with version prefix)
  static const String songsEndpoint = '/api/$apiVersion/songs';
  static const String userSongsEndpoint = '/api/$apiVersion/songs/user';
  static const String uploadEndpoint = '/api/$apiVersion/songs/upload';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
