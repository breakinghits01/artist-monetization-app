import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallet_model.dart';

/// Wallet provider
final walletProvider =
    StateNotifierProvider<WalletNotifier, AsyncValue<WalletModel>>(
      (ref) => WalletNotifier(),
    );

class WalletNotifier extends StateNotifier<AsyncValue<WalletModel>> {
  WalletNotifier() : super(const AsyncValue.loading()) {
    loadWallet();
  }

  Future<void> loadWallet() async {
    try {
      state = const AsyncValue.loading();

      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock data for now
      final wallet = WalletModel(tokens: 1250, balance: 12.50, currency: 'USD');

      state = AsyncValue.data(wallet);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addTokens(int amount) async {
    state.whenData((wallet) {
      state = AsyncValue.data(wallet.copyWith(tokens: wallet.tokens + amount));
    });
  }

  Future<void> updateBalance(double amount) async {
    state.whenData((wallet) {
      state = AsyncValue.data(
        wallet.copyWith(balance: wallet.balance + amount),
      );
    });
  }

  Future<void> refresh() async {
    await loadWallet();
  }
}
