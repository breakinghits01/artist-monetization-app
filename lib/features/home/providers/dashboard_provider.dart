import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_card_model.dart';
import '../../artist/providers/artist_provider.dart';

/// Dashboard cards provider
final dashboardCardsProvider =
    StateNotifierProvider<
      DashboardCardsNotifier,
      AsyncValue<List<DashboardCardModel>>
    >((ref) => DashboardCardsNotifier(ref));

class DashboardCardsNotifier
    extends StateNotifier<AsyncValue<List<DashboardCardModel>>> {
  final Ref _ref;
  
  DashboardCardsNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadCards();
  }

  Future<void> loadCards() async {
    try {
      state = const AsyncValue.loading();

      await Future.delayed(const Duration(milliseconds: 500));

      // Build cards list
      final cards = <DashboardCardModel>[
        DashboardCardModel(
          id: '1',
          type: DashboardCardType.trendingPlaylist,
          title: 'Hot Hits 2026',
          subtitle: '🔥 12K plays today',
          imageUrl: '',
          metadata: {'playCount': 12000, 'trendPercentage': 85},
          createdAt: DateTime.now(),
        ),
        // Rising Stars card
        DashboardCardModel(
          id: '2',
          type: DashboardCardType.risingStars,
          title: 'Rising Stars',
          subtitle: 'Top trending artists this month',
          imageUrl: '',
          metadata: {},
          createdAt: DateTime.now(),
        ),
      ];
      // Add other static cards
      cards.addAll([
        DashboardCardModel(
          id: '3',
          type: DashboardCardType.dailyChallenge,
          title: 'Listen to 5 songs',
          subtitle: 'Complete: 3/5',
          metadata: {'current': 3, 'target': 5, 'reward': 100},
          createdAt: DateTime.now(),
        ),
        DashboardCardModel(
          id: '4',
          type: DashboardCardType.exclusiveBundle,
          title: 'Summer Vibes Pack',
          subtitle: '💎 500 tokens • 10 songs',
          imageUrl: '',
          metadata: {'tokenCost': 500, 'songCount': 10},
          createdAt: DateTime.now(),
        ),
        DashboardCardModel(
          id: '5',
          type: DashboardCardType.newSingle,
          title: 'Midnight Dreams',
          subtitle: 'by DJ Alex • 100 tokens',
          imageUrl: '',
          metadata: {'tokenCost': 100, 'artist': 'DJ Alex'},
          createdAt: DateTime.now(),
        ),
        DashboardCardModel(
          id: '6',
          type: DashboardCardType.earningOpportunity,
          title: 'Refer a Friend',
          subtitle: 'Earn 100 tokens',
          metadata: {'reward': 100},
          createdAt: DateTime.now(),
        ),
      ]);

      state = AsyncValue.data(cards);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    // Invalidate featured artist to get fresh data
    _ref.invalidate(featuredArtistProvider);
    await loadCards();
  }
}
