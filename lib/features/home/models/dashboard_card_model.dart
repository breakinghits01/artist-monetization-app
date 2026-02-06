/// Dashboard card types for masonry grid
enum DashboardCardType {
  trendingPlaylist,
  artistSpotlight,
  exclusiveBundle,
  newSingle,
  dailyChallenge,
  earningOpportunity,
  yourCollection,
  topTippers,
}

/// Model for dashboard card items
class DashboardCardModel {
  final String id;
  final DashboardCardType type;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const DashboardCardModel({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.metadata,
    required this.createdAt,
  });

  factory DashboardCardModel.fromJson(Map<String, dynamic> json) {
    return DashboardCardModel(
      id: json['_id'] as String,
      type: _cardTypeFromString(json['type'] as String),
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      imageUrl: json['imageUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type.name,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static DashboardCardType _cardTypeFromString(String value) {
    return DashboardCardType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => DashboardCardType.trendingPlaylist,
    );
  }
}
