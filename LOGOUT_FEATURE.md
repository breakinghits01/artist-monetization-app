# Logout Feature & Persistent Authentication

## ✅ Features Implemented

### 1. **Persistent Authentication**
Users stay logged in across app restarts (proper mobile app behavior)

**How it works:**
- Tokens are stored securely using `flutter_secure_storage`
  - iOS: Keychain
  - Android: EncryptedSharedPreferences
- User data is saved in secure storage
- On app startup, auth state is automatically restored
- App checks for valid tokens and loads user data

**User Experience:**
```
First Launch → Login → Close App → Reopen App → Still Logged In ✅
```

### 2. **Logout Functionality**
Complete logout with confirmation dialog

**Features:**
- Logout button in home screen AppBar
- Confirmation dialog before logout
- Clears all stored data (tokens + user info)
- Calls API to invalidate server-side tokens
- Redirects to login screen automatically

**User Experience:**
```
Home Screen → Tap Logout → Confirm → Login Screen
```

### 3. **Auth State Management**
Centralized authentication state with Riverpod

**Auth Provider** (`lib/features/auth/providers/auth_provider.dart`):
- `isAuthenticated` - Whether user is logged in
- `isLoading` - Loading state for auth operations
- `isInitialized` - Whether auth check is complete
- `user` - Current user data
- `error` - Error message if any

**Available Actions:**
- `login()` - Login with email/password
- `register()` - Create new account
- `logout()` - Logout and clear data
- `refreshToken()` - Refresh expired token

### 4. **Route Guards**
Automatic navigation based on auth state

**Protected Routes:**
- `/home` - Requires authentication
- Any future protected routes

**Public Routes:**
- `/` - Splash screen
- `/login` - Login page
- `/register` - Registration page
- `/forgot-password` - Password reset

**Behavior:**
- Not logged in + trying to access protected route → Redirect to Login
- Logged in + trying to access auth routes → Redirect to Home
- Logged in + app restart → Stay on Home

## 📱 User Flows

### First Time User
```
1. Launch App → Splash Screen (2s)
2. Auto-redirect to Login (no token found)
3. Click "Register"
4. Fill form + Submit
5. Auto-redirect to Home (token saved)
6. Close app
7. Reopen app → Splash → Home (still logged in) ✅
```

### Returning User
```
1. Launch App → Splash Screen (2s)
2. Auto-redirect to Home (token found + valid)
3. See profile with username, email, role
4. Browse app features
```

### Logout Flow
```
1. On Home Screen
2. Tap logout icon (top right)
3. Confirmation dialog appears
   "Are you sure you want to logout?"
   [Cancel] [Logout]
4. Tap "Logout"
5. Loading indicator (brief)
6. Success message: "Logged out successfully"
7. Auto-redirect to Login screen
8. All data cleared from device
```

## 🔐 Security Features

### Token Storage
- **Access Token**: Short-lived (15 min)
- **Refresh Token**: Long-lived (7 days)
- Stored in platform-specific secure storage
- Never stored in plain text
- Automatically cleared on logout

### Auto Token Refresh
- When API returns 401 (Unauthorized)
- Automatically refreshes using refresh token
- If refresh fails → Auto logout
- Seamless for user (no interruption)

### Session Management
- Server-side session tracking
- Tokens invalidated on logout (API call)
- Multiple device support
- Secure token rotation on refresh

## 🎯 Implementation Details

### Auth Provider Initialization
```dart
// In auth_provider.dart
AuthNotifier() : super(AuthState()) {
  _initializeAuth(); // Called automatically
}

_initializeAuth() async {
  // 1. Check if access token exists
  // 2. Load user data from storage
  // 3. Update state (authenticated or not)
  // 4. Router handles navigation
}
```

### Login Process
```dart
await ref.read(authProvider.notifier).login(
  email: email,
  password: password,
);

// Behind the scenes:
// 1. Call API /auth/login
// 2. Receive tokens + user data
// 3. Save to secure storage
// 4. Update auth state
// 5. Router redirects to /home
```

### Logout Process
```dart
await ref.read(authProvider.notifier).logout();

// Behind the scenes:
// 1. Call API /auth/logout (invalidate token)
// 2. Clear all secure storage
// 3. Reset auth state
// 4. Router redirects to /login
```

### Router Redirect Logic
```dart
redirect: (context, state) {
  // Wait for initialization
  if (!authState.isInitialized) return '/';
  
  // Check authentication
  final isAuthenticated = authState.isAuthenticated;
  final isAuthRoute = ['/login', '/register', ...];
  
  // Redirect rules:
  // - Not auth + protected → Login
  // - Auth + auth route → Home
  // - Otherwise → Continue
}
```

## 🧪 Testing the Feature

### Test Persistent Login
1. Run app in Chrome: `flutter run -d chrome`
2. Login with test account
3. Close browser tab
4. Reopen http://localhost:xxxxx
5. Should show Home screen (still logged in) ✅

### Test Logout
1. On Home screen
2. Click logout icon (top right)
3. Confirm dialog
4. Should redirect to Login ✅
5. Try accessing /home directly → Redirected to Login ✅

### Test Auto Token Refresh
1. Login
2. Wait 15+ minutes (token expires)
3. Make API request
4. Token auto-refreshes
5. Request succeeds ✅

### Test Route Guards
1. Not logged in → Try accessing `/home` → Redirected to `/login` ✅
2. Logged in → Try accessing `/login` → Redirected to `/home` ✅
3. Logged in → Refresh page → Stay on Home ✅

## 📊 State Flow Diagram

```
App Launch
    ↓
Splash Screen (init auth)
    ↓
Check Storage
    ├─ Has Token? ─→ Load User Data ─→ Home Screen
    └─ No Token? ─→ Login Screen
                        ↓
                     Login/Register
                        ↓
                   Save Tokens
                        ↓
                   Home Screen
                        ↓
                   [Use App]
                        ↓
                   Tap Logout
                        ↓
                  Confirm Dialog
                        ↓
                 Clear Storage
                        ↓
                  Login Screen
```

## 🎨 UI Updates

### Home Screen
**Before:**
- Basic welcome message
- Theme toggle
- Settings button

**After:**
- User profile card (avatar, username, email, role badge)
- Welcome message with name
- Theme toggle
- **Logout button** with confirmation

### Auth Screens
**Before:**
- Forms with TODO comments

**After:**
- Fully functional with API integration
- Loading states during auth
- Error handling with user-friendly messages
- Success messages
- Auto-navigation after success

## 🚀 Next Steps

Current implementation is complete for:
- ✅ Persistent authentication
- ✅ Logout functionality
- ✅ Route guards
- ✅ Token management
- ✅ Auto token refresh

Optional enhancements:
- [ ] Remember me checkbox
- [ ] Biometric authentication
- [ ] Multi-device session management UI
- [ ] Active sessions list
- [ ] Force logout all devices
- [ ] Session timeout warning
- [ ] Activity tracking

## 📝 Usage Examples

### Check if User is Logged In
```dart
final isAuthenticated = ref.watch(isAuthenticatedProvider);
```

### Get Current User
```dart
final user = ref.watch(currentUserProvider);
final username = user?['username'];
final email = user?['email'];
final role = user?['role'];
```

### Logout Programmatically
```dart
await ref.read(authProvider.notifier).logout();
```

### Listen to Auth State Changes
```dart
ref.listen(authProvider, (previous, next) {
  if (next.error != null) {
    // Show error
  }
  if (next.isAuthenticated) {
    // User logged in
  }
});
```

## ✅ Status: COMPLETE

The logout feature is fully implemented with proper mobile app behavior. Users stay logged in across app restarts and can logout with a smooth confirmation dialog. All authentication is handled securely with encrypted storage and automatic token refresh.
