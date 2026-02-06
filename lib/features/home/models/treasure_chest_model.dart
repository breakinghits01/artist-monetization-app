/// Treasure chest status
enum TreasureStatus { locked, ready, opened }

/// Model for treasure chest rewards
class TreasureChestModel {
  final String id;
  final String name;
  final String description;
  final TreasureStatus status;
  final DateTime? unlockTime;
  final int? tokensCost;
  final List<TreasureReward> rewards;
  final String imageUrl;

  const TreasureChestModel({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    this.unlockTime,
    this.tokensCost,
    required this.rewards,
    required this.imageUrl,
  });

  factory TreasureChestModel.fromJson(Map<String, dynamic> json) {
    return TreasureChestModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      status: _statusFromString(json['status'] as String),
      unlockTime: json['unlockTime'] != null
          ? DateTime.parse(json['unlockTime'] as String)
          : null,
      tokensCost: json['tokensCost'] as int?,
      rewards: (json['rewards'] as List)
          .map((r) => TreasureReward.fromJson(r as Map<String, dynamic>))
          .toList(),
      imageUrl: json['imageUrl'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'status': status.name,
      'unlockTime': unlockTime?.toIso8601String(),
      'tokensCost': tokensCost,
      'rewards': rewards.map((r) => r.toJson()).toList(),
      'imageUrl': imageUrl,
    };
  }

  static TreasureStatus _statusFromString(String value) {
    return TreasureStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => TreasureStatus.locked,
    );
  }

  /// Check if chest is ready to open
  bool get isReady => status == TreasureStatus.ready;

  /// Check if chest is locked
  bool get isLocked => status == TreasureStatus.locked;

  /// Check if chest is already opened
  bool get isOpened => status == TreasureStatus.opened;

  /// Get time remaining until unlock
  Duration? get timeRemaining {
    if (unlockTime == null) return null;
    final now = DateTime.now();
    if (now.isAfter(unlockTime!)) return Duration.zero;
    return unlockTime!.difference(now);
  }
}

/// Model for treasure rewards
class TreasureReward {
  final String type; // 'tokens', 'song_credit', 'bundle'
  final int? amount;
  final String? itemId;
  final String description;

  const TreasureReward({
    required this.type,
    this.amount,
    this.itemId,
    required this.description,
  });

  factory TreasureReward.fromJson(Map<String, dynamic> json) {
    return TreasureReward(
      type: json['type'] as String,
      amount: json['amount'] as int?,
      itemId: json['itemId'] as String?,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'amount': amount,
      'itemId': itemId,
      'description': description,
    };
  }

  String get emoji {
    switch (type) {
      case 'tokens':
        return '🪙';
      case 'song_credit':
        return '🎵';
      case 'bundle':
        return '📦';
      default:
        return '🎁';
    }
  }
}
