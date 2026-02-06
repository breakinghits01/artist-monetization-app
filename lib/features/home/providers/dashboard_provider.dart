import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_card_model.dart';

/// Dashboard cards provider
final dashboardCardsProvider =
    StateNotifierProvider<
      DashboardCardsNotifier,
      AsyncValue<List<DashboardCardModel>>
    >((ref) => DashboardCardsNotifier());

class DashboardCardsNotifier
    extends StateNotifier<AsyncValue<List<DashboardCardModel>>> {
  DashboardCardsNotifier() : super(const AsyncValue.loading()) {
    loadCards();
  }

  Future<void> loadCards() async {
    try {
      state = const AsyncValue.loading();

      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 700));

      // Mock data
      final cards = [
        DashboardCardModel(
          id: '1',
          type: DashboardCardType.trendingPlaylist,
          title: 'Hot Hits 2026',
          subtitle: '🔥 12K plays today',
          imageUrl: '',
          metadata: {'playCount': 12000, 'trendPercentage': 85},
          createdAt: DateTime.now(),
        ),
        DashboardCardModel(
          id: '2',
          type: DashboardCardType.artistSpotlight,
          title: 'Rising Star',
          subtitle: '1.2K followers • 45 songs',
          imageUrl: '',
          metadata: {'followers': 1200, 'songs': 45},
          createdAt: DateTime.now(),
        ),
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
      ];

      state = AsyncValue.data(cards);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadCards();
  }
}
