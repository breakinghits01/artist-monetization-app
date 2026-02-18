import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

import '../../../core/services/auth_api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/dio_client.dart';

/// Authentication State
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final bool isInitialized;
  final String? error;
  final Map<String, dynamic>? user;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.isInitialized = false,
    this.error,
    this.user,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? isInitialized,
    String? error,
    Map<String, dynamic>? user,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
      user: user ?? this.user,
    );
  }

  bool get isArtist => user?['role'] == 'artist';
  bool get isFan => user?['role'] == 'fan';
  String? get username => user?['username'];
  String? get email => user?['email'];
}

/// Authentication Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApiService _authService = AuthApiService();
  final StorageService _storage = StorageService();

  AuthNotifier() : super(AuthState()) {
    _initializeAuth();
  }

  /// Initialize authentication state on app start
  /// Checks if user has valid tokens and loads user data
  Future<void> _initializeAuth() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Check if access token exists (handles corrupted storage internally)
      final hasToken = await _authService.isAuthenticated();
      
      if (hasToken) {
        // Load saved user data (handles corrupted storage internally)
        final userDataString = await _storage.getUserData();
        
        if (userDataString != null) {
          final userData = jsonDecode(userDataString);
          
          state = state.copyWith(
            isAuthenticated: true,
            isLoading: false,
            isInitialized: true,
            user: userData,
          );
          
          debugPrint('✅ User restored from storage: ${userData['email']}');
        } else {
          // Token exists but no user data - clear tokens
          await _authService.logout();
          state = state.copyWith(
            isAuthenticated: false,
            isLoading: false,
            isInitialized: true,
          );
        }
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          isInitialized: true,
        );
      }
    } catch (e) {
      // Silently handle storage errors - corrupted data is auto-cleared
      debugPrint('⚠️ Auth init: Storage error handled (corrupted data cleared)');
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        isInitialized: true,
      );
    }
  }

  /// Login with email and password
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );
      
      // Save user data to storage for persistence
      final userData = response['user'];
      await _storage.saveUserData(jsonEncode(userData));
      
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: userData,
        error: null,
      );
      
      debugPrint('✅ Login successful: ${userData['email']}');
    } on ApiException catch (e) {
      debugPrint('❌ Login error: ${e.message}');
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      rethrow;
    } catch (e) {
      debugPrint('❌ Unexpected login error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Register new user
  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _authService.register(
        username: username,
        email: email,
        password: password,
        role: role,
      );
      
      // Do NOT save user data or set isAuthenticated
      // User needs to login manually after registration
      state = state.copyWith(
        isLoading: false,
        error: null,
      );
      
      debugPrint('✅ Registration successful: $email');
    } on ApiException catch (e) {
      debugPrint('❌ Registration error: ${e.message}');
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      rethrow;
    } catch (e) {
      debugPrint('❌ Unexpected registration error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Logout user
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Call API to invalidate tokens on server
      await _authService.logout();
      
      // Clear all local data
      await _storage.clearAll();
      
      // Reset state
      state = AuthState(isInitialized: true);
      
      debugPrint('✅ Logout successful');
    } catch (e) {
      debugPrint('❌ Logout error: $e');
      
      // Even if API call fails, clear local data
      await _storage.clearAll();
      state = AuthState(isInitialized: true);
    }
  }

  /// Refresh access token
  Future<void> refreshToken() async {
    try {
      await _authService.refreshToken();
      debugPrint('✅ Token refreshed successfully');
    } catch (e) {
      debugPrint('❌ Token refresh failed: $e');
      // If refresh fails, logout user
      await logout();
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

/// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final currentUserProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

final isAuthInitializedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isInitialized;
});
