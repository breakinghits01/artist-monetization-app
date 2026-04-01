/// A single plan's feature flags, mirroring the API response
class PlanFeatures {
  final bool streaming;
  final bool downloads;
  final int downloadLimit; // -1 = unlimited, 0 = none
  final bool exclusiveContent;
  final String audioQuality;
  final bool adsEnabled;
  final int skipLimitPerHour; // -1 = unlimited
  final bool earlyAccess;

  const PlanFeatures({
    required this.streaming,
    required this.downloads,
    required this.downloadLimit,
    required this.exclusiveContent,
    required this.audioQuality,
    required this.adsEnabled,
    required this.skipLimitPerHour,
    required this.earlyAccess,
  });

  factory PlanFeatures.fromMap(Map<String, dynamic> map) {
    return PlanFeatures(
      streaming: (map['streaming'] as bool?) ?? true,
      downloads: (map['downloads'] as bool?) ?? false,
      downloadLimit: (map['downloadLimit'] as num?)?.toInt() ?? 0,
      exclusiveContent: (map['exclusiveContent'] as bool?) ?? false,
      audioQuality: (map['audioQuality'] as String?) ?? 'Standard',
      adsEnabled: (map['adsEnabled'] as bool?) ?? true,
      skipLimitPerHour: (map['skipLimitPerHour'] as num?)?.toInt() ?? 6,
      earlyAccess: (map['earlyAccess'] as bool?) ?? false,
    );
  }

  /// User-friendly bullet points shown on the plans screen
  List<String> get bulletPoints {
    final points = <String>[];
    if (streaming) points.add('Unlimited streaming');
    if (downloads) {
      if (downloadLimit == -1) {
        points.add('Unlimited offline downloads');
      } else {
        points.add('Download up to $downloadLimit songs/month');
      }
    } else {
      points.add('No offline downloads');
    }
    points.add(audioQuality);
    if (!adsEnabled) {
      points.add('Ad-free listening');
    } else {
      points.add('Includes ads');
    }
    if (skipLimitPerHour == -1) {
      points.add('Unlimited skips');
    } else {
      points.add('$skipLimitPerHour skips/hour');
    }
    if (exclusiveContent) points.add('Exclusive artist content');
    if (earlyAccess) points.add('Early access to new releases');
    return points;
  }
}

/// A subscription plan as returned by GET /subscription/plans
class PlanModel {
  final String id;
  final String name;
  final int price; // in PHP centavos
  final String currency;
  final String? period;
  final PlanFeatures features;

  const PlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    this.period,
    required this.features,
  });

  factory PlanModel.fromMap(Map<String, dynamic> map) {
    return PlanModel(
      id: map['id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num?)?.toInt() ?? 0,
      currency: (map['currency'] as String?) ?? 'PHP',
      period: map['period'] as String?,
      features: PlanFeatures.fromMap(
        (map['features'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  bool get isFree => price == 0;

  String get formattedPrice {
    if (isFree) return 'Free';
    return '₱$price / ${period ?? 'month'}';
  }
}
