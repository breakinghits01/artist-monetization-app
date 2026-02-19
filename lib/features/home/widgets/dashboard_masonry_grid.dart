import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/responsive.dart';
import '../models/dashboard_card_model.dart';
import '../providers/dashboard_provider.dart';
import 'dashboard_cards/artist_spotlight_card.dart';
import 'dashboard_cards/challenge_card.dart';
import 'dashboard_cards/playlist_card.dart';

/// Pinterest-style masonry grid for dashboard cards
class DashboardMasonryGrid extends ConsumerWidget {
  const DashboardMasonryGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(dashboardCardsProvider);
    final columnCount = Responsive.getMasonryColumns(context);
    final isDesktop = Responsive.isDesktop(context);

    return cards.when(
      data: (cardsList) {
        if (cardsList.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No content available'),
            ),
          );
        }

        return MasonryGridView.count(
          crossAxisCount: columnCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: isDesktop ? 16 : 12,
          crossAxisSpacing: isDesktop ? 16 : 12,
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          itemCount: cardsList.length,
          itemBuilder: (context, index) {
            return _buildCard(cardsList[index]);
          },
        );
      },
      loading: () => _buildLoadingGrid(context),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Failed to load content: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(DashboardCardModel card) {
    switch (card.type) {
      case DashboardCardType.artistSpotlight:
        return ArtistSpotlightCard(card: card);
      case DashboardCardType.trendingPlaylist:
        return PlaylistCard(card: card);
      case DashboardCardType.dailyChallenge:
        return ChallengeCard(card: card);
      case DashboardCardType.exclusiveBundle:
      case DashboardCardType.newSingle:
      case DashboardCardType.earningOpportunity:
      case DashboardCardType.yourCollection:
      case DashboardCardType.topTippers:
        return _DefaultCard(card: card);
    }
  }

  Widget _buildLoadingGrid(BuildContext context) {
    final columnCount = Responsive.getMasonryColumns(context);
    final isDesktop = Responsive.isDesktop(context);
    
    return MasonryGridView.count(
      crossAxisCount: columnCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: isDesktop ? 16 : 12,
      crossAxisSpacing: isDesktop ? 16 : 12,
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      itemCount: columnCount * 2, // Show 2 rows of loading cards
      itemBuilder: (context, index) => _LoadingCard(),
    );
  }
}

/// Default card for unspecified types
class _DefaultCard extends StatelessWidget {
  final DashboardCardModel card;

  const _DefaultCard({required this.card});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (card.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(card.subtitle!, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading skeleton card
class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = (100 + (context.hashCode % 100)).toDouble();

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
