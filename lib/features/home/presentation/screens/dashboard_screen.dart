import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/theme_switcher.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../discover/screens/discover_screen.dart';
import '../../../connect/screens/connect_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../upload/presentation/upload_screen.dart';
import '../../../player/widgets/player_wrapper.dart';
import '../../../player/widgets/mini_player.dart';
import '../../../player/providers/audio_player_provider.dart';
import '../../widgets/wallet_header.dart';
import '../../widgets/story_circles.dart';
import '../../widgets/treasure_chest_card.dart';
import '../../widgets/treasure_chest_banner.dart';
import '../../widgets/dashboard_masonry_grid.dart';
import '../../widgets/web_sidebar.dart';
import '../../widgets/web_top_bar.dart';
import '../../providers/treasure_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/story_provider.dart';
import '../../providers/wallet_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _DashboardTab(),
    const DiscoverScreen(),
    const UploadScreen(),
    const ConnectScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentSong = ref.watch(currentSongProvider);
    final isPlayerExpanded = ref.watch(playerExpandedProvider);

    // Use responsive web layout for desktop/tablet
    if (Responsive.isDesktop(context)) {
      return PlayerWrapper(
        child: Scaffold(
          body: Row(
            children: [
              WebSidebar(
                selectedIndex: _selectedIndex,
                onNavigate: _onItemTapped,
              ),
              Expanded(
                child: Column(
                  children: [
                    const WebTopBar(),
                    Expanded(
                      child: _screens[_selectedIndex],
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomSheet: currentSong != null && !isPlayerExpanded
              ? const MiniPlayer()
              : null,
        ),
      );
    }

    // Mobile layout (unchanged)
    return PlayerWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.music_note, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                _getAppBarTitle(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            const ThemeSwitcher(),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () => _showLogoutDialog(context, ref),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _screens[_selectedIndex],
        // Bottom area with mini player + navigation bar
        bottomNavigationBar: isPlayerExpanded
            ? null
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mini player sits here if there's a song playing
                  if (currentSong != null) ...[
                    const MiniPlayer(),
                    const SizedBox(height: 0), // No gap needed, they should touch
                  ],
                  // Navigation bar below mini player
                  NavigationBar(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _onItemTapped,
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                    height: 64,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.home_outlined, size: 28),
                        selectedIcon: Icon(Icons.home_rounded, size: 28),
                        label: '',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.explore_outlined, size: 28),
                        selectedIcon: Icon(Icons.explore_rounded, size: 28),
                        label: '',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.add_circle_outline, size: 28),
                        selectedIcon: Icon(Icons.add_circle, size: 28),
                        label: '',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.people_outline_rounded, size: 28),
                        selectedIcon: Icon(Icons.people_rounded, size: 28),
                        label: '',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.account_circle_outlined, size: 28),
                        selectedIcon: Icon(Icons.account_circle, size: 28),
                        label: '',
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Treasure Hunt';
      case 1:
        return 'Discover';
      case 2:
        return 'Upload Music';
      case 3:
        return 'Connect';
      case 4:
        return 'Profile';
      default:
        return 'Dynamic Artist';
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    // Capture context before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = GoRouter.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              // Perform logout
              await ref.read(authProvider.notifier).logout();
              
              // Show success snackbar
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Row(
                    children: const [
                      Icon(Icons.logout_rounded, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Logged Out Successfully',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.blueGrey.shade700,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              );
              
              // Navigate to login
              await Future.delayed(const Duration(milliseconds: 500));
              navigator.go('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// Dashboard Tab Widget
class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final treasure = ref.watch(treasureProvider);
    final isDesktop = Responsive.isDesktop(context);

    return RefreshIndicator(
      onRefresh: () => _refreshDashboard(ref),
      child: CustomScrollView(
        slivers: [
          // Wallet header (mobile only)
          if (!isDesktop) const SliverToBoxAdapter(child: WalletHeader()),

          // Stories section (mobile only)
          if (!isDesktop) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            const SliverToBoxAdapter(child: StoryCircles()),
          ],

          // Treasure chest section
          SliverToBoxAdapter(
            child: treasure.when(
              data: (chest) {
                if (chest == null) return const SizedBox.shrink();
                // Use horizontal banner on desktop, vertical card on mobile
                return isDesktop
                    ? const TreasureChestBanner()
                    : TreasureChestCard(chest: chest);
              },
              loading: () => Container(
                margin: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 16,
                  vertical: isDesktop ? 16 : 8,
                ),
                height: isDesktop ? 120 : 300,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(isDesktop ? 20 : 24),
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => const SizedBox.shrink(),
            ),
          ),

          // Dashboard section title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Discover More',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Masonry grid
          const SliverToBoxAdapter(child: DashboardMasonryGrid()),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Future<void> _refreshDashboard(WidgetRef ref) async {
    await Future.wait([
      ref.read(walletProvider.notifier).loadWallet(),
      ref.read(storiesProvider.notifier).refresh(),
      ref.read(treasureProvider.notifier).refresh(),
      ref.read(dashboardCardsProvider.notifier).refresh(),
    ]);
  }
}
