/// Challenge status
enum ChallengeStatus { active, completed, expired }

/// Daily challenge model
class ChallengeModel {
  final String id;
  final String title;
  final String description;
  final ChallengeStatus status;
  final int currentProgress;
  final int targetProgress;
  final List<ChallengeReward> rewards;
  final DateTime startTime;
  final DateTime endTime;
  final String? iconUrl;

  const ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.currentProgress,
    required this.targetProgress,
    required this.rewards,
    required this.startTime,
    required this.endTime,
    this.iconUrl,
  });

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: _statusFromString(json['status'] as String),
      currentProgress: json['currentProgress'] as int? ?? 0,
      targetProgress: json['targetProgress'] as int,
      rewards: (json['rewards'] as List)
          .map((r) => ChallengeReward.fromJson(r as Map<String, dynamic>))
          .toList(),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      iconUrl: json['iconUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'currentProgress': currentProgress,
      'targetProgress': targetProgress,
      'rewards': rewards.map((r) => r.toJson()).toList(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'iconUrl': iconUrl,
    };
  }

  static ChallengeStatus _statusFromString(String value) {
    return ChallengeStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => ChallengeStatus.active,
    );
  }

  /// Calculate progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (targetProgress == 0) return 0.0;
    return (currentProgress / targetProgress).clamp(0.0, 1.0);
  }

  /// Check if challenge is completed
  bool get isCompleted =>
      status == ChallengeStatus.completed || currentProgress >= targetProgress;

  /// Check if challenge is expired
  bool get isExpired =>
      status == ChallengeStatus.expired || DateTime.now().isAfter(endTime);

  /// Get time remaining
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endTime)) return Duration.zero;
    return endTime.difference(now);
  }

  /// Format time remaining
  String get formattedTimeRemaining {
    final duration = timeRemaining;
    if (duration == Duration.zero) return 'Expired';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 24) {
      final days = (hours / 24).floor();
      return '${days}d left';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m left';
    } else {
      return '${minutes}m left';
    }
  }
}

/// Challenge reward model
class ChallengeReward {
  final String type; // 'tokens', 'badge', 'song_credit'
  final int? amount;
  final String? itemId;
  final String description;

  const ChallengeReward({
    required this.type,
    this.amount,
    this.itemId,
    required this.description,
  });

  factory ChallengeReward.fromJson(Map<String, dynamic> json) {
    return ChallengeReward(
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
      case 'badge':
        return '🏆';
      case 'song_credit':
        return '🎵';
      default:
        return '🎁';
    }
  }
}
