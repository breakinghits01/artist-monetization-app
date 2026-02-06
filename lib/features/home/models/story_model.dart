/// Artist story model for story circles
class StoryModel {
  final String id;
  final String artistId;
  final String artistName;
  final String artistAvatar;
  final String? genre;
  final bool isLive;
  final bool hasNewContent;
  final bool isExclusive;
  final List<StoryItem> items;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const StoryModel({
    required this.id,
    required this.artistId,
    required this.artistName,
    required this.artistAvatar,
    this.genre,
    required this.isLive,
    required this.hasNewContent,
    required this.isExclusive,
    required this.items,
    required this.createdAt,
    this.expiresAt,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['_id'] as String,
      artistId: json['artistId'] as String,
      artistName: json['artistName'] as String,
      artistAvatar: json['artistAvatar'] as String,
      genre: json['genre'] as String?,
      isLive: json['isLive'] as bool? ?? false,
      hasNewContent: json['hasNewContent'] as bool? ?? false,
      isExclusive: json['isExclusive'] as bool? ?? false,
      items:
          (json['items'] as List?)
              ?.map((i) => StoryItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'artistId': artistId,
      'artistName': artistName,
      'artistAvatar': artistAvatar,
      'genre': genre,
      'isLive': isLive,
      'hasNewContent': hasNewContent,
      'isExclusive': isExclusive,
      'items': items.map((i) => i.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  /// Check if story is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Get genre color
  String get genreColor {
    switch (genre?.toLowerCase()) {
      case 'rock':
        return '#FF6B6B';
      case 'jazz':
        return '#4ECDC4';
      case 'pop':
        return '#FFE66D';
      case 'electronic':
        return '#A8E6CF';
      case 'hip hop':
        return '#FF8B94';
      case 'classical':
        return '#C7CEEA';
      default:
        return '#B4A7D6';
    }
  }
}

/// Story item (individual slide in story)
class StoryItem {
  final String id;
  final String type; // 'image', 'video', 'song', 'announcement'
  final String? mediaUrl;
  final String? text;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const StoryItem({
    required this.id,
    required this.type,
    this.mediaUrl,
    this.text,
    this.metadata,
    required this.createdAt,
  });

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    return StoryItem(
      id: json['_id'] as String,
      type: json['type'] as String,
      mediaUrl: json['mediaUrl'] as String?,
      text: json['text'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      'mediaUrl': mediaUrl,
      'text': text,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
