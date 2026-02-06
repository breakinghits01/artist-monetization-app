enum ActivityType {
  follow('follow'),
  songUpload('song_upload'),
  exclusiveRelease('exclusive_release'),
  bundleCreated('bundle_created');

  final String value;
  const ActivityType(this.value);

  static ActivityType fromString(String value) {
    return ActivityType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ActivityType.follow,
    );
  }
}

class ActivityModel {
  final String id;
  final ActivityUser user;
  final ActivityType type;
  final ActivityTarget? target;
  final String message;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  ActivityModel({
    required this.id,
    required this.user,
    required this.type,
    this.target,
    required this.message,
    this.metadata,
    required this.createdAt,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['_id'] as String,
      user: ActivityUser.fromJson(json['userId'] as Map<String, dynamic>),
      type: ActivityType.fromString(json['type'] as String),
      target: json['targetId'] != null
          ? ActivityTarget.fromJson(json['targetId'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get activityIcon {
    switch (type) {
      case ActivityType.follow:
        return '👥';
      case ActivityType.songUpload:
        return '🎵';
      case ActivityType.exclusiveRelease:
        return '⭐';
      case ActivityType.bundleCreated:
        return '📦';
    }
  }
}

class ActivityUser {
  final String id;
  final String username;
  final String? profilePicture;

  ActivityUser({
    required this.id,
    required this.username,
    this.profilePicture,
  });

  factory ActivityUser.fromJson(Map<String, dynamic> json) {
    return ActivityUser(
      id: json['_id'] as String,
      username: json['username'] as String,
      profilePicture: json['profilePicture'] as String?,
    );
  }
}

class ActivityTarget {
  final String id;
  final String? title;
  final String? name;
  final String? coverArt;

  ActivityTarget({
    required this.id,
    this.title,
    this.name,
    this.coverArt,
  });

  factory ActivityTarget.fromJson(Map<String, dynamic> json) {
    return ActivityTarget(
      id: json['_id'] as String,
      title: json['title'] as String?,
      name: json['name'] as String?,
      coverArt: json['coverArt'] as String?,
    );
  }

  String get displayName => title ?? name ?? 'Unknown';
}
