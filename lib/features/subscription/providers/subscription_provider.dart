import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_config.dart';
import '../../../core/services/dio_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/plan_model.dart';
import '../models/subscription_model.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class SubscriptionState {
  final SubscriptionModel subscription;
  final List<PlanModel> plans;
  final bool isLoadingSubscription;
  final bool isLoadingPlans;
  final String? error;

  const SubscriptionState({
    this.subscription = const SubscriptionModel(),
    this.plans = const [],
    this.isLoadingSubscription = false,
    this.isLoadingPlans = false,
    this.error,
  });

  SubscriptionState copyWith({
    SubscriptionModel? subscription,
    List<PlanModel>? plans,
    bool? isLoadingSubscription,
    bool? isLoadingPlans,
    String? error,
  }) {
    return SubscriptionState(
      subscription: subscription ?? this.subscription,
      plans: plans ?? this.plans,
      isLoadingSubscription:
          isLoadingSubscription ?? this.isLoadingSubscription,
      isLoadingPlans: isLoadingPlans ?? this.isLoadingPlans,
      error: error,
    );
  }

  bool get canDownload => subscription.canDownload;
  bool get isPremium => subscription.isPremium;
  bool get isAdvanced => subscription.isAdvanced;
  SubscriptionTier get tier => subscription.tier;
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final Ref _ref;

  SubscriptionNotifier(this._ref) : super(const SubscriptionState()) {
    _initFromAuthState();
  }

  /// Seed subscription from already-loaded user data in AuthState
  /// so there's zero extra API call on init.
  void _initFromAuthState() {
    final user = _ref.read(authProvider).user;
    if (user != null) {
      final sub = SubscriptionModel.fromMap(
        user['subscription'] as Map<String, dynamic>?,
      );
      state = state.copyWith(subscription: sub);
    }

    // Also load plans in the background (they're public / cached)
    fetchPlans();
  }

  /// Refresh from the /subscription/me endpoint (call after login or on profile open)
  Future<void> fetchMySubscription() async {
    state = state.copyWith(isLoadingSubscription: true, error: null);
    try {
      final dio = DioClient.instance;
      final response = await dio
          .get('${ApiConfig.baseUrl}${ApiConfig.mySubscriptionEndpoint}');

      if (response.statusCode == 200) {
        final data = response.data['data']['subscription'] as Map<String, dynamic>?;
        state = state.copyWith(
          subscription: SubscriptionModel.fromMap(data),
          isLoadingSubscription: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingSubscription: false,
        error: 'Failed to load subscription',
      );
    }
  }

  /// Fetch plan definitions (public — no auth needed)
  Future<void> fetchPlans() async {
    if (state.plans.isNotEmpty) return; // already cached
    state = state.copyWith(isLoadingPlans: true, error: null);
    try {
      final dio = DioClient.instance;
      final response = await dio
          .get('${ApiConfig.baseUrl}${ApiConfig.subscriptionPlansEndpoint}');

      if (response.statusCode == 200) {
        final rawPlans =
            response.data['data']['plans'] as List<dynamic>? ?? [];
        final plans = rawPlans
            .map((p) => PlanModel.fromMap(p as Map<String, dynamic>))
            .toList();
        state = state.copyWith(plans: plans, isLoadingPlans: false);
      }
    } catch (e) {
      state = state.copyWith(isLoadingPlans: false, error: 'Failed to load plans');
    }
  }

  /// Called by AuthNotifier after a successful login to re-seed subscription
  void updateFromUser(Map<String, dynamic>? user) {
    final sub = SubscriptionModel.fromMap(
      user?['subscription'] as Map<String, dynamic>?,
    );
    state = state.copyWith(subscription: sub);
  }

  /// Clear subscription on logout
  void clear() {
    state = const SubscriptionState();
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  final notifier = SubscriptionNotifier(ref);

  // Re-sync subscription when auth user changes (e.g. after login/logout)
  ref.listen<AuthState>(authProvider, (previous, next) {
    if (next.isAuthenticated && next.user != null) {
      notifier.updateFromUser(next.user);
    } else if (!next.isAuthenticated) {
      notifier.clear();
    }
  });

  return notifier;
});

/// Convenience: whether the current user can download songs
final canDownloadProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider).canDownload;
});

/// Convenience: current subscription tier
final subscriptionTierProvider = Provider<SubscriptionTier>((ref) {
  return ref.watch(subscriptionProvider).tier;
});
