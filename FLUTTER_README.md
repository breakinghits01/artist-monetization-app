# Flutter Frontend Setup - Artist Monetization Platform

## Features Implemented

### ✅ Theme System
- **Light & Dark Theme** with smooth transitions
- **Google Fonts Integration** (Inter font family)
- **Theme Persistence** using SharedPreferences
- **Theme Toggle** in app bar with icon indicator

### ✅ Authentication Screens
- **Splash Screen** with animated logo
- **Login Screen** with email/password validation
- **Register Screen** with role selection (Fan/Artist)
- **Forgot Password Screen** with success confirmation

### ✅ Routing
- **go_router** configuration with named routes
- **Custom transitions** (fade animations)
- **Error handling** with 404 page
- **Deep linking ready**

### ✅ State Management
- **Riverpod** for global state
- **Theme provider** with automatic persistence
- Clean separation of concerns

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart         # App-wide constants
│   ├── router/
│   │   └── app_router.dart            # Route configuration
│   └── theme/
│       ├── app_theme.dart             # Light & dark themes
│       └── theme_provider.dart        # Theme state management
├── features/
│   ├── auth/
│   │   └── presentation/
│   │       └── screens/
│   │           ├── login_screen.dart
│   │           ├── register_screen.dart
│   │           └── forgot_password_screen.dart
│   ├── home/
│   │   └── presentation/
│   │       └── screens/
│   │           └── home_screen.dart   # Home with theme toggle
│   └── splash/
│       └── presentation/
│           └── screens/
│               └── splash_screen.dart # Animated splash
└── main.dart                          # App entry point
```

## Theme Configuration

### Colors
- **Primary Light**: `#6200EE` (Purple)
- **Primary Dark**: `#BB86FC` (Light Purple)
- **Secondary**: `#03DAC6` (Teal)
- **Background Light**: `#FAFAFA`
- **Background Dark**: `#121212`

### Typography
- **Font Family**: Inter (Google Fonts)
- **Responsive text sizes** with proper hierarchy
- **Font weights**: 400 (normal), 500 (medium), 600 (semi-bold), 700 (bold)

## Running the App

### Prerequisites
```bash
flutter pub get
```

### Run on Chrome (Web)
```bash
flutter run -d chrome
```

### Run on iOS Simulator
```bash
flutter run -d "iPhone 15 Pro"
```

### Run on Android Emulator
```bash
flutter run -d emulator-5554
```

## Testing Theme Switching

1. Launch the app
2. Wait for splash screen (2 seconds)
3. Navigate to login screen
4. After login, you'll see the home screen
5. **Tap the theme icon** (sun/moon) in the app bar
6. Theme will toggle between light and dark
7. **Theme preference persists** across app restarts

## API Integration (TODO)

The following files are prepared with TODO comments for API integration:

1. **Login Screen**: `_handleLogin()` method
2. **Register Screen**: `_handleRegister()` method
3. **Forgot Password**: `_handleSendResetEmail()` method

### Next Steps:
- Create API service layer with Dio + Retrofit
- Add token storage with flutter_secure_storage
- Implement auto token refresh
- Add loading states and error handling

## Available Routes

| Route | Path | Description |
|-------|------|-------------|
| Splash | `/` | Initial loading screen |
| Login | `/login` | User login |
| Register | `/register` | New user registration |
| Forgot Password | `/forgot-password` | Password reset request |
| Home | `/home` | Main screen (authenticated) |

## Validation Rules

### Email
- Must be valid email format
- Regex: `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`

### Password
- Minimum 8 characters
- Must contain:
  - At least one uppercase letter
  - At least one lowercase letter
  - At least one number
  - At least one special character (@$!%*?&#)

### Username
- 3-30 characters
- Only letters, numbers, and underscores
- Regex: `^[a-zA-Z0-9_]+$`

## Backend Integration

### Base URL
```dart
static const String baseUrl = 'http://localhost:3000';
static const String apiVersion = '/api/v1';
```

### API Endpoints (Ready to use)
- `POST /api/v1/auth/register` - User registration
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/refresh` - Token refresh
- `POST /api/v1/auth/logout` - User logout
- `POST /api/v1/auth/forgot-password` - Request password reset
- `POST /api/v1/auth/reset-password` - Reset password with token
- `GET /api/v1/auth/verify-email` - Verify email address

## Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.6.1      # State management
  go_router: ^14.8.1             # Routing
  dio: ^5.4.3                    # HTTP client
  retrofit: ^4.4.1               # Type-safe API client
  google_fonts: ^6.2.1           # Custom fonts
  flutter_secure_storage: ^9.2.2 # Secure token storage
  shared_preferences: ^2.3.4     # Settings persistence
  cached_network_image: ^3.4.1  # Image caching
  shimmer: ^3.0.0                # Loading animations
```

## Screenshots

### Light Theme
- Clean, modern interface
- Purple primary color
- White surfaces

### Dark Theme
- OLED-friendly blacks
- Reduced eye strain
- Light purple accents

## Performance

- **Initial load**: ~2s (splash screen)
- **Route transitions**: Smooth fade animations
- **Theme switching**: Instant with automatic persistence
- **Hot reload**: Fully supported

## Error Handling

- Form validation with clear error messages
- Network error handling (ready for implementation)
- 404 page for invalid routes
- Success/error snackbars

## Accessibility

- High contrast in both themes
- Clear visual hierarchy
- Icon + text labels
- Keyboard navigation support (web)

## Future Enhancements

- [ ] API service layer implementation
- [ ] Token management and auto-refresh
- [ ] User profile management
- [ ] Music player integration
- [ ] Treasure chest UI
- [ ] Tipping system
- [ ] Analytics and tracking
- [ ] Push notifications
- [ ] Offline support

## Notes

- Theme preference is stored locally and persists across sessions
- All screens are responsive and work on mobile, tablet, and desktop
- The app uses Material 3 design system
- Google Fonts are downloaded and cached automatically
