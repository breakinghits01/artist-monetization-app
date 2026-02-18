import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Secure Storage Service
/// 
/// Handles secure storage of sensitive data like tokens using
/// flutter_secure_storage which uses:
/// - Keychain on iOS
/// - EncryptedSharedPreferences on Android
/// - libsecret on Linux
/// - Windows Credential Store on Windows
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Token Management
  Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(key: AppConstants.accessTokenKey, value: token);
    } catch (e) {
      print('⚠️ Failed to save access token: $e');
      // Clear corrupted storage and retry
      await _clearCorruptedStorage();
      await _storage.write(key: AppConstants.accessTokenKey, value: token);
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: AppConstants.accessTokenKey);
    } catch (e) {
      print('⚠️ Failed to read access token (corrupted): $e');
      await _clearCorruptedStorage();
      return null;
    }
  }

  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: AppConstants.refreshTokenKey, value: token);
    } catch (e) {
      print('⚠️ Failed to save refresh token: $e');
      await _clearCorruptedStorage();
      await _storage.write(key: AppConstants.refreshTokenKey, value: token);
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: AppConstants.refreshTokenKey);
    } catch (e) {
      print('⚠️ Failed to read refresh token (corrupted): $e');
      await _clearCorruptedStorage();
      return null;
    }
  }

  Future<void> deleteTokens() async {
    try {
      await _storage.delete(key: AppConstants.accessTokenKey);
      await _storage.delete(key: AppConstants.refreshTokenKey);
    } catch (e) {
      print('⚠️ Failed to delete tokens: $e');
      await _clearCorruptedStorage();
    }
  }

  // User Data Management
  Future<void> saveUserData(String userData) async {
    try {
      await _storage.write(key: AppConstants.userDataKey, value: userData);
    } catch (e) {
      print('⚠️ Failed to save user data: $e');
      await _clearCorruptedStorage();
      await _storage.write(key: AppConstants.userDataKey, value: userData);
    }
  }

  Future<String?> getUserData() async {
    try {
      return await _storage.read(key: AppConstants.userDataKey);
    } catch (e) {
      print('⚠️ Failed to read user data (corrupted): $e');
      await _clearCorruptedStorage();
      return null;
    }
  }

  Future<void> deleteUserData() async {
    try {
      await _storage.delete(key: AppConstants.userDataKey);
    } catch (e) {
      print('⚠️ Failed to delete user data: $e');
      await _clearCorruptedStorage();
    }
  }

  // Clear corrupted storage
  Future<void> _clearCorruptedStorage() async {
    try {
      print('🧹 Clearing corrupted secure storage...');
      await _storage.deleteAll();
      print('✅ Corrupted storage cleared');
    } catch (e) {
      print('❌ Failed to clear storage: $e');
    }
  }

  // Clear All Data
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      print('⚠️ Failed to clear all storage: $e');
    }
  }

  // Generic methods for custom data
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      print('⚠️ Failed to write $key: $e');
      await _clearCorruptedStorage();
      await _storage.write(key: key, value: value);
    }
  }

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      print('⚠️ Failed to read $key (corrupted): $e');
      await _clearCorruptedStorage();
      return null;
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      print('⚠️ Failed to delete $key: $e');
      await _clearCorruptedStorage();
    }
  }

  Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      print('⚠️ Failed to read all (corrupted): $e');
      await _clearCorruptedStorage();
      return {};
    }
  }

  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      print('⚠️ Failed to check key $key: $e');
      return false;
    }
  }
}
