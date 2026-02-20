import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/home/presentation/screens/dashboard_screen.dart';
import '../../features/home/widgets/desktop_layout.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/discover/screens/discover_screen.dart';
import '../../features/connect/screens/connect_screen.dart';
import '../../features/upload/presentation/upload_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../screens/download_history_screen.dart';
import '../constants/app_constants.dart';

/// Router configuration provider with auth guards
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppConstants.splashRoute,
    debugLogDiagnostics: false,
    routes: [
      // Splash Screen
      GoRoute(
        path: AppConstants.splashRoute,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: AppConstants.loginRoute,
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      GoRoute(
        path: AppConstants.registerRoute,
        name: 'register',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      GoRoute(
        path: AppConstants.forgotPasswordRoute,
        name: 'forgot-password',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Home Route - Uses shell route for desktop, direct for mobile
      ShellRoute(
        builder: (context, state, child) {
          // Use desktop layout only on web and wider screens
          if (kIsWeb) {
            return LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 900) {
                  return DesktopLayout(child: child);
                }
                return child; // Mobile gets direct route
              },
            );
          }
          return child; // Native apps get direct route
        },
        routes: [
          GoRoute(
            path: AppConstants.homeRoute,
            name: 'home',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/discover',
            name: 'discover',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const DiscoverScreen(),
            ),
          ),
          GoRoute(
            path: '/upload',
            name: 'upload',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const UploadScreen(),
            ),
          ),
          GoRoute(
            path: '/connect',
            name: 'connect',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ConnectScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ProfileScreen(),
            ),
          ),
        ],
      ),

      // Notifications Route (standalone, not in shell)
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NotificationsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),

      // Download History Route
      GoRoute(
        path: '/downloads',
        name: 'downloads',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DownloadHistoryScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),

      // Add more routes here as needed
    ],

    // Redirect logic for authentication
    redirect: (context, state) {
      // Wait for auth initialization
      if (!authState.isInitialized) {
        return AppConstants.splashRoute;
      }

      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == AppConstants.loginRoute ||
          state.matchedLocation == AppConstants.registerRoute ||
          state.matchedLocation == AppConstants.forgotPasswordRoute;
      
      final isSplashRoute = state.matchedLocation == AppConstants.splashRoute;

      // If on splash and initialized, redirect appropriately
      if (isSplashRoute && authState.isInitialized) {
        return isAuthenticated ? AppConstants.homeRoute : AppConstants.loginRoute;
      }

      // If not authenticated and trying to access protected route
      if (!isAuthenticated && !isAuthRoute && !isSplashRoute) {
        return AppConstants.loginRoute;
      }

      // Don't auto-redirect authenticated users from auth routes
      // Let the screens handle navigation with proper success messages
      // This allows snackbars to be visible before navigation

      return null; // No redirect needed
    },

    // Error handler
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppConstants.splashRoute),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),

    // Redirect logic can be added here
    // redirect: (context, state) {
    //   final isAuthenticated = authState.isAuthenticated;
    //   final isAuthRoute = state.matchedLocation.startsWith('/login') ||
    //       state.matchedLocation.startsWith('/register');
    //
    //   if (!isAuthenticated && !isAuthRoute) {
    //     return AppConstants.loginRoute;
    //   }
    //
    //   if (isAuthenticated && isAuthRoute) {
    //     return AppConstants.homeRoute;
    //   }
    //
    //   return null; // No redirect
    // },
  );
});
