import 'package:flutter/material.dart';

/// Responsive breakpoints for the application
class Responsive {
  // Breakpoint constants
  static const double mobileMaxWidth = 900;
  static const double tabletMaxWidth = 1200;
  static const double desktopMaxWidth = 1600;

  /// Check if the current screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileMaxWidth;
  }

  /// Check if the current screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileMaxWidth && width < tabletMaxWidth;
  }

  /// Check if the current screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletMaxWidth;
  }

  /// Check if the current screen is large desktop
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopMaxWidth;
  }

  /// Get the number of columns for masonry grid based on screen width
  static int getMasonryColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileMaxWidth) return 2;
    if (width < tabletMaxWidth) return 3;
    if (width < desktopMaxWidth) return 4;
    return 5;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }

  /// Get responsive value based on screen size
  static T getValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
}
