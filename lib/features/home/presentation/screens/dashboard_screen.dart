import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/theme_switcher.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../discover/screens/discover_screen.dart';
import '../../../connect/screens/connect_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../player/widgets/player_wrapper.dart';
import '../../../player/widgets/mini_player.dart';
import '../../../player/providers/audio_player_provider.dart';
import '../../widgets/wallet_header.dart';
import '../../widgets/story_circles.dart';
import '../../widgets/treasure_chest_card.dart';
import '../../widgets/dashboard_masonry_grid.dart';
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
    const ConnectScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final currentSong = ref.watch(currentSongProvider);
    final isPlayerExpanded = ref.watch(playerExpandedProvider);

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
            GestureDetector(
              onTap: () => context.push('/profile'),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary,
                backgroundImage: user?['profileImage'] != null
                    ? NetworkImage(user!['profileImage'] as String)
                    : null,
                child: user?['profileImage'] == null
                    ? Icon(
                        Icons.person,
                        size: 20,
                        color: theme.colorScheme.onPrimary,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
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
                  if (currentSong != null) const MiniPlayer(),
                  // Navigation bar below mini player
                  NavigationBar(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _onItemTapped,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.explore_outlined),
                        selectedIcon: Icon(Icons.explore),
                        label: 'Discover',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.people_outline),
                        selectedIcon: Icon(Icons.people),
                        label: 'Connect',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person),
                        label: 'Profile',
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
        return 'Connect';
      case 3:
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

    return RefreshIndicator(
      onRefresh: () => _refreshDashboard(ref),
      child: CustomScrollView(
        slivers: [
          // Wallet header
          const SliverToBoxAdapter(child: WalletHeader()),

          // Stories section
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          const SliverToBoxAdapter(child: StoryCircles()),

          // Treasure chest section
          SliverToBoxAdapter(
            child: treasure.when(
              data: (chest) {
                if (chest == null) return const SizedBox.shrink();
                return TreasureChestCard(chest: chest);
              },
              loading: () => Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                height: 300,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
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
