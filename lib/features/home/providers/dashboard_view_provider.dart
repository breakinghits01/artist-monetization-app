import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents the different views that can be displayed in the dashboard content area
enum DashboardView {
  /// Default dashboard with masonry grid cards
  dashboard,
  
  /// Trending songs view
  trending,
  
  /// Rising stars rankings view
  risingStars,
}

/// Provider for managing the active dashboard view
/// This allows seamless switching between different content views
/// without full navigation, keeping the sidebar and layout consistent
final dashboardViewProvider = StateProvider<DashboardView>((ref) {
  return DashboardView.dashboard;
});

/// Provider for tracking if we should show back button in content header
/// Used when navigating from dashboard to trending/rising stars
final showContentBackButtonProvider = StateProvider<bool>((ref) {
  return false;
});
