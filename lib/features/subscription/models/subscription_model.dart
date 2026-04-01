/// Subscription tier levels
enum SubscriptionTier {
  free,
  premium,
  advanced;

  /// Parse from API string value
  static SubscriptionTier fromString(String? value) {
    switch (value) {
      case 'premium':
        return SubscriptionTier.premium;
      case 'advanced':
        return SubscriptionTier.advanced;
      default:
        return SubscriptionTier.free;
    }
  }

  /// API string value
  String get value {
    switch (this) {
      case SubscriptionTier.free:
        return 'free';
      case SubscriptionTier.premium:
        return 'premium';
      case SubscriptionTier.advanced:
        return 'advanced';
    }
  }

  /// Display name
  String get displayName {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.premium:
        return 'Premium';
      case SubscriptionTier.advanced:
        return 'Advanced';
    }
  }

  /// Whether this tier can download songs for offline listening
  bool get canDownload => this != SubscriptionTier.free;

  /// Whether this tier has unlimited downloads
  bool get hasUnlimitedDownloads => this == SubscriptionTier.advanced;

  /// Whether this tier sees ads
  bool get hasAds => this == SubscriptionTier.free;

  /// Numeric rank for tier comparisons (higher = better)
  int get rank {
    switch (this) {
      case SubscriptionTier.free:
        return 0;
      case SubscriptionTier.premium:
        return 1;
      case SubscriptionTier.advanced:
        return 2;
    }
  }

  /// Whether this tier is at least [other]
  bool isAtLeast(SubscriptionTier other) => rank >= other.rank;
}

/// Subscription status
enum SubscriptionStatus {
  active,
  cancelled,
  expired,
  trial;

  static SubscriptionStatus fromString(String? value) {
    switch (value) {
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'trial':
        return SubscriptionStatus.trial;
      default:
        return SubscriptionStatus.active;
    }
  }
}

/// User's current subscription details
class SubscriptionModel {
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? cancelledAt;
  final int downloadCount;
  final int downloadLimit; // -1 = unlimited

  const SubscriptionModel({
    this.tier = SubscriptionTier.free,
    this.status = SubscriptionStatus.active,
    this.startDate,
    this.endDate,
    this.cancelledAt,
    this.downloadCount = 0,
    this.downloadLimit = 0,
  });

  /// Default free subscription (used for legacy users or unauthenticated states)
  factory SubscriptionModel.defaultFree() => const SubscriptionModel();

  factory SubscriptionModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return SubscriptionModel.defaultFree();
    return SubscriptionModel(
      tier: SubscriptionTier.fromString(map['tier'] as String?),
      status: SubscriptionStatus.fromString(map['status'] as String?),
      startDate: map['startDate'] != null
          ? DateTime.tryParse(map['startDate'] as String)
          : null,
      endDate: map['endDate'] != null
          ? DateTime.tryParse(map['endDate'] as String)
          : null,
      cancelledAt: map['cancelledAt'] != null
          ? DateTime.tryParse(map['cancelledAt'] as String)
          : null,
      downloadCount: (map['downloadCount'] as num?)?.toInt() ?? 0,
      downloadLimit: (map['downloadLimit'] as num?)?.toInt() ?? 0,
    );
  }

  /// Downloads remaining this cycle (-1 = unlimited, 0 = none)
  int get downloadsRemaining {
    if (downloadLimit == -1) return -1; // unlimited
    return (downloadLimit - downloadCount).clamp(0, downloadLimit);
  }

  bool get canDownload => tier.canDownload && status == SubscriptionStatus.active;

  bool get isActive => status == SubscriptionStatus.active;

  bool get isPremium => tier == SubscriptionTier.premium && isActive;

  bool get isAdvanced => tier == SubscriptionTier.advanced && isActive;

  @override
  String toString() =>
      'SubscriptionModel(tier: ${tier.value}, status: ${status.name}, downloads: $downloadCount/$downloadLimit)';
}
