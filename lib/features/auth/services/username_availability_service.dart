import 'dart:async';
import '../../../core/services/dio_client.dart';
import '../../../core/constants/app_constants.dart';

/// Service for checking username and email availability
/// 
/// Features:
/// - Debounced API calls (500ms)
/// - Caching to reduce duplicate requests
/// - Proper error handling
class AvailabilityService {
  final Map<String, bool> _usernameCache = {};
  final Map<String, bool> _emailCache = {};
  Timer? _usernameDebounce;
  Timer? _emailDebounce;

  /// Check if username is available
  /// Returns true if available, false if taken
  Future<bool> checkUsernameAvailability(String username) async {
    // Check cache first
    if (_usernameCache.containsKey(username)) {
      return _usernameCache[username]!;
    }

    try {
      final response = await DioClient.instance.get(
        '${AppConstants.apiBaseUrl}/auth/check-username/$username',
      );

      final isAvailable = response.data['available'] == true;
      _usernameCache[username] = isAvailable;
      return isAvailable;
    } catch (e) {
      // On error, assume unavailable to be safe
      return false;
    }
  }

  /// Check if email is available
  /// Returns true if available, false if taken
  Future<bool> checkEmailAvailability(String email) async {
    // Check cache first
    if (_emailCache.containsKey(email)) {
      return _emailCache[email]!;
    }

    try {
      final encodedEmail = Uri.encodeComponent(email);
      final response = await DioClient.instance.get(
        '${AppConstants.apiBaseUrl}/auth/check-email/$encodedEmail',
      );

      final isAvailable = response.data['available'] == true;
      _emailCache[email] = isAvailable;
      return isAvailable;
    } catch (e) {
      // On error, assume unavailable to be safe
      return false;
    }
  }

  /// Debounced username check
  Future<bool> checkUsernameDebounced(
    String username,
    Function(bool) onResult,
  ) async {
    _usernameDebounce?.cancel();
    
    final completer = Completer<bool>();
    
    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      final result = await checkUsernameAvailability(username);
      onResult(result);
      completer.complete(result);
    });

    return completer.future;
  }

  /// Debounced email check
  Future<bool> checkEmailDebounced(
    String email,
    Function(bool) onResult,
  ) async {
    _emailDebounce?.cancel();
    
    final completer = Completer<bool>();
    
    _emailDebounce = Timer(const Duration(milliseconds: 500), () async {
      final result = await checkEmailAvailability(email);
      onResult(result);
      completer.complete(result);
    });

    return completer.future;
  }

  /// Clear cache
  void clearCache() {
    _usernameCache.clear();
    _emailCache.clear();
  }

  /// Dispose timers
  void dispose() {
    _usernameDebounce?.cancel();
    _emailDebounce?.cancel();
  }
}
