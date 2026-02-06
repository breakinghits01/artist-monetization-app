# API Integration Guide

## Quick Start

The API service layer is fully implemented and ready to use. Here's how to integrate it with your authentication screens.

## Step 1: Update Login Screen

Replace the `_handleLogin()` method in [login_screen.dart](lib/features/auth/presentation/screens/login_screen.dart):

```dart
Future<void> _handleLogin() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() => _isLoading = true);

  try {
    final authService = AuthApiService();
    final response = await authService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.loginSuccessMessage),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to home
      context.go(AppConstants.homeRoute);
    }
  } on ApiException catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

**Import required:**
```dart
import '../../../../core/services/auth_api_service.dart';
import '../../../../core/services/dio_client.dart'; // For ApiException
import '../../../../core/constants/app_constants.dart';
```

## Step 2: Update Register Screen

Replace the `_handleRegister()` method in [register_screen.dart](lib/features/auth/presentation/screens/register_screen.dart):

```dart
Future<void> _handleRegister() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() => _isLoading = true);

  try {
    final authService = AuthApiService();
    await authService.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.registerSuccessMessage),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate to home (or login if email verification required)
      context.go(AppConstants.homeRoute);
    }
  } on ApiException catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

## Step 3: Update Forgot Password Screen

Replace the `_handleSendResetEmail()` method in [forgot_password_screen.dart](lib/features/auth/presentation/screens/forgot_password_screen.dart):

```dart
Future<void> _handleSendResetEmail() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() => _isLoading = true);

  try {
    final authService = AuthApiService();
    await authService.forgotPassword(
      email: _emailController.text.trim(),
    );

    setState(() => _emailSent = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.passwordResetEmailSentMessage),
          backgroundColor: Colors.green,
        ),
      );
    }
  } on ApiException catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send reset email: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

## Step 4: Create Authentication Provider (Optional but Recommended)

Create `lib/features/auth/providers/auth_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_api_service.dart';
import '../../../core/services/dio_client.dart';

/// Authentication State
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? user;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.user,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? user,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      user: user ?? this.user,
    );
  }
}

/// Authentication Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApiService _authService = AuthApiService();

  AuthNotifier() : super(AuthState()) {
    _checkAuthStatus();
  }

  /// Check if user is already authenticated
  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final isAuth = await _authService.isAuthenticated();
      state = state.copyWith(
        isAuthenticated: isAuth,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
      );
    }
  }

  /// Login
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
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: response['user'],
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      rethrow;
    }
  }

  /// Register
  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.register(
        username: username,
        email: email,
        password: password,
        role: role,
      );
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: response['user'],
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      rethrow;
    }
  }

  /// Logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.logout();
      state = AuthState(); // Reset to initial state
    } catch (e) {
      // Still logout locally even if API fails
      state = AuthState();
    }
  }

  /// Refresh Token
  Future<void> refreshToken() async {
    try {
      await _authService.refreshToken();
    } catch (e) {
      // If refresh fails, logout
      await logout();
    }
  }
}

/// Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
```

## Step 5: Update Router with Auth Guards

Update [app_router.dart](lib/core/router/app_router.dart):

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppConstants.splashRoute,
    debugLogDiagnostics: true,
    routes: [
      // ... existing routes
    ],
    
    // Add redirect logic
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/forgot-password') ||
          state.matchedLocation == '/';

      // If not authenticated and trying to access protected route
      if (!isAuthenticated && !isAuthRoute) {
        return AppConstants.loginRoute;
      }

      // If authenticated and trying to access auth route
      if (isAuthenticated && isAuthRoute && state.matchedLocation != '/') {
        return AppConstants.homeRoute;
      }

      return null; // No redirect needed
    },
  );
});
```

## Step 6: Using the Provider in Screens

**Login Screen with Provider:**

```dart
class _LoginScreenState extends ConsumerState<LoginScreen> {
  // ... existing code

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await ref.read(authProvider.notifier).login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Navigation handled automatically by router redirect
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
```

## Testing the Integration

### 1. Start Backend API
```bash
cd api_dynamic_artist_monetization
pm2 status
# If not running: pm2 start ecosystem.config.js --env development
```

### 2. Verify Backend is Running
```bash
curl http://localhost:3000/health
# Should return: {"status":"OK"}
```

### 3. Test Registration Flow
1. Run Flutter app
2. Click "Register"
3. Fill form with:
   - Username: testuser
   - Email: test@example.com
   - Password: Test@1234
   - Role: Fan
4. Submit form
5. Check console for API logs
6. Should navigate to home screen

### 4. Test Login Flow
1. Click "Login"
2. Enter:
   - Email: test@example.com
   - Password: Test@1234
3. Submit form
4. Should navigate to home screen

### 5. Test Forgot Password
1. Click "Forgot Password"
2. Enter email
3. Submit
4. Check backend logs for email (currently logged, not sent)

## Error Handling

The API service automatically handles:
- ✅ Network timeouts
- ✅ Connection errors
- ✅ 401 Unauthorized (auto token refresh)
- ✅ 400/422 Validation errors
- ✅ 500 Server errors
- ✅ Token storage and retrieval

## Security Features

- ✅ Tokens stored in secure storage (Keychain/EncryptedSharedPreferences)
- ✅ Auto token refresh on 401
- ✅ HTTPS ready
- ✅ Request/response logging (disable in production)
- ✅ Timeout configuration

## Production Checklist

Before deploying to production:

1. **Remove Debug Logging**
   - Remove `print()` statements from dio_client.dart
   - Set `debugLogDiagnostics: false` in router

2. **Update Base URL**
   - Change `baseUrl` in app_constants.dart to production URL
   - Add environment variable support

3. **Add Error Tracking**
   - Integrate Sentry or Firebase Crashlytics
   - Log API errors to analytics

4. **Add Loading States**
   - Show loading overlay during API calls
   - Add skeleton screens

5. **Test Edge Cases**
   - Poor network conditions
   - Token expiration
   - Invalid credentials
   - Server downtime

## Environment Configuration

Create `.env` file (add to .gitignore):

```env
API_BASE_URL=http://localhost:3000
API_VERSION=v1
ENABLE_LOGGING=true
```

Use `flutter_dotenv` to load:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const ProviderScope(child: MyApp()));
}

// In app_constants.dart
static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
```

## Common Issues

### Issue: Connection Refused
**Solution**: Make sure backend is running on `localhost:3000`

### Issue: Token Not Saved
**Solution**: Check secure storage permissions in AndroidManifest.xml

### Issue: 401 After Login
**Solution**: Verify token is being sent in Authorization header

### Issue: CORS Error (Web)
**Solution**: Backend already has CORS enabled for `http://localhost:*`

## Next Steps

1. ✅ API service layer implemented
2. ✅ Secure storage configured
3. ✅ Error handling ready
4. ⏳ Update auth screens with API calls
5. ⏳ Implement auth provider
6. ⏳ Add route guards
7. ⏳ Create user profile screen
8. ⏳ Add logout functionality
9. ⏳ Implement auto token refresh
10. ⏳ Add loading states and error UI

## Support

If you encounter any issues:
1. Check backend PM2 logs: `pm2 logs artist-api-dev`
2. Check Flutter console for API errors
3. Verify network connectivity
4. Check token storage: `await StorageService().readAll()`
