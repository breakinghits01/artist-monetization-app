import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/treasure_chest_model.dart';

/// Treasure provider
final treasureProvider =
    StateNotifierProvider<TreasureNotifier, AsyncValue<TreasureChestModel?>>(
      (ref) => TreasureNotifier(),
    );

class TreasureNotifier extends StateNotifier<AsyncValue<TreasureChestModel?>> {
  TreasureNotifier() : super(const AsyncValue.loading()) {
    loadDailyTreasure();
  }

  Future<void> loadDailyTreasure() async {
    try {
      state = const AsyncValue.loading();

      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock data - chest ready in 2 hours
      final treasure = TreasureChestModel(
        id: '1',
        name: 'Daily Treasure Chest',
        description: 'Your free daily rewards',
        status: TreasureStatus.locked,
        unlockTime: DateTime.now().add(const Duration(hours: 2, minutes: 34)),
        tokensCost: 50,
        rewards: [
          const TreasureReward(
            type: 'tokens',
            amount: 250,
            description: '100-500 tokens',
          ),
          const TreasureReward(
            type: 'song_credit',
            amount: 1,
            description: 'Free song credit',
          ),
        ],
        imageUrl: '',
      );

      state = AsyncValue.data(treasure);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> openChest(String chestId) async {
    state.whenData((chest) {
      if (chest != null && chest.isReady) {
        // TODO: Call API to open chest
        final openedChest = TreasureChestModel(
          id: chest.id,
          name: chest.name,
          description: chest.description,
          status: TreasureStatus.opened,
          rewards: chest.rewards,
          imageUrl: chest.imageUrl,
        );
        state = AsyncValue.data(openedChest);
      }
    });
  }

  Future<void> unlockWithTokens(String chestId) async {
    state.whenData((chest) {
      if (chest != null && chest.tokensCost != null) {
        // TODO: Call API to unlock with tokens
        final unlockedChest = TreasureChestModel(
          id: chest.id,
          name: chest.name,
          description: chest.description,
          status: TreasureStatus.ready,
          rewards: chest.rewards,
          imageUrl: chest.imageUrl,
        );
        state = AsyncValue.data(unlockedChest);
      }
    });
  }

  Future<void> refresh() async {
    await loadDailyTreasure();
  }
}
