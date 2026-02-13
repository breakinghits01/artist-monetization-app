import 'package:flutter/material.dart';

/// Extension on ColorScheme to provide custom app-specific colors
/// that adapt to light/dark theme automatically
extension AppColors on ColorScheme {
  /// Token reward colors (gold)
  /// Used for token displays, rewards, and premium features
  Color get tokenPrimary => brightness == Brightness.dark 
      ? const Color(0xFFFFD700) // Bright gold for dark theme
      : const Color(0xFFFFAA00); // Darker gold for light theme
  
  Color get tokenSecondary => brightness == Brightness.dark
      ? const Color(0xFFFFAA00) // Amber for dark theme
      : const Color(0xFFFFD700); // Gold for light theme
  
  /// Surface variant colors for cards and containers
  /// Provides subtle variations from the default surface color
  Color get surfaceVariant2 => brightness == Brightness.dark 
      ? const Color(0xFF1A1F3A) // Dark blue surface
      : const Color(0xFFF5F5F5); // Light grey surface
  
  Color get surfaceVariant3 => brightness == Brightness.dark 
      ? const Color(0xFF2A3150) // Slightly lighter dark surface
      : const Color(0xFFEEEEEE); // Slightly darker light surface
  
  /// Container colors for special UI elements
  Color get containerDark => brightness == Brightness.dark
      ? const Color(0xFF1A1F3A)
      : Colors.grey[200]!;
  
  Color get containerLight => brightness == Brightness.dark
      ? const Color(0xFF2A3150)
      : Colors.grey[100]!;
  
  /// Background variants for different sections
  Color get backgroundDeep => brightness == Brightness.dark
      ? const Color(0xFF0A0E27) // Deep navy background
      : const Color(0xFFFAFAFA); // Very light grey
  
  /// Accent colors for special highlights
  /// These complement the primary theme colors
  Color get accentPurple => const Color(0xFF9C27B0); // Purple
  Color get accentDeepPurple => const Color(0xFF7B2CBF); // Deep purple
  Color get accentHotPink => const Color(0xFFFF10F0); // Hot magenta
  
  /// Status colors remain consistent across themes
  Color get statusSuccess => const Color(0xFF00E676);
  Color get statusWarning => const Color(0xFFFFB300);
  Color get statusError => const Color(0xFFFF4444);
}
