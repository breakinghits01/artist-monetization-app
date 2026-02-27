import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/rising_stars_provider.dart';
import '../widgets/artist_ranking_card.dart';
import '../models/artist_ranking_model.dart';

/// Rising Stars screen with professional layout matching trending
class RisingStarsScreen extends ConsumerStatefulWidget {
  const RisingStarsScreen({super.key});

  @override
  ConsumerState<RisingStarsScreen> createState() => _RisingStarsScreenState();
}

class _RisingStarsScreenState extends ConsumerState<RisingStarsScreen>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    
    // Load rankings on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(risingStarsProvider.notifier).loadRankings();
    });

    // Setup pagination scroll listener
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      // Load more when 90% scrolled
      ref.read(risingStarsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(risingStarsProvider);

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Hero Header with expandable app bar
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Rising Stars',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Hero(
                    tag: 'rising_stars_card',
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.withValues(alpha: 0.9),
                            Colors.orange.withValues(alpha: 0.9),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Decorative elements
                          Positioned(
                            right: -50,
                            top: -50,
                            child: Icon(
                              Icons.emoji_events,
                              size: 200,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          Positioned(
                            left: 20,
                            bottom: 60,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade700,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '⭐ RISING',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Filter Chips Section
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildFilterChips(context, state, theme),
                ),
              ),

              // Rankings List or States
              if (state.isLoading && state.artists.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.error != null && state.artists.isEmpty)
                SliverFillRemaining(
                  child: _buildErrorState(context, state, theme),
                )
              else if (state.artists.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(context, theme),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == state.artists.length) {
                          return state.isLoadingMore
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : const SizedBox.shrink();
                        }

                        final artist = state.artists[index];
                        final rank = index + 1;

                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: ArtistRankingCard(
                            artist: artist,
                            rank: rank,
                          ),
                        );
                      },
                      childCount: state.artists.length + (state.isLoadingMore ? 1 : 0),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    RisingStarsState state,
    ThemeData theme,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  theme.colorScheme.surface,
                  theme.colorScheme.surface.withValues(alpha: 0.8),
                ]
              : [
                  Colors.amber.withValues(alpha: 0.05),
                  Colors.orange.withValues(alpha: 0.05),
                ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.amber.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: Colors.amber.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Time Period',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Modern Period Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TimeWindow.values.map((window) {
                final isSelected = window == state.timeWindow;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _ModernFilterButton(
                    label: window.label,
                    description: window.description,
                    isSelected: isSelected,
                    onTap: () {
                      ref
                          .read(risingStarsProvider.notifier)
                          .changeTimeWindow(window);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Formula Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.tune,
                  size: 18,
                  color: Colors.amber.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Ranking Formula',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Modern Formula Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: FormulaType.values.map((formula) {
                final isSelected = formula == state.formula;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _ModernFilterButton(
                    label: formula.label,
                    description: formula.description,
                    isSelected: isSelected,
                    icon: _getFormulaIcon(formula),
                    onTap: () {
                      ref
                          .read(risingStarsProvider.notifier)
                          .changeFormula(formula);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    RisingStarsState state,
    ThemeData theme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to load rankings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              state.error ?? 'An error occurred',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.read(risingStarsProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Rising Stars Yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Check back later for trending artists',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFormulaIcon(FormulaType formula) {
    switch (formula) {
      case FormulaType.balanced:
        return Icons.balance;
      case FormulaType.viral:
        return Icons.rocket_launch;
      case FormulaType.engaged:
        return Icons.chat_bubble;
      case FormulaType.growth:
        return Icons.trending_up;
    }
  }
}

/// Modern filter button widget
class _ModernFilterButton extends StatelessWidget {
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const _ModernFilterButton({
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    Colors.amber.shade600,
                    Colors.orange.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : isDark
                  ? theme.colorScheme.surfaceContainerHighest
                  : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.amber.shade700
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected
                        ? Colors.white
                        : Colors.amber.shade700,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.white,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.9)
                    : theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
