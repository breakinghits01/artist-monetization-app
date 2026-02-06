class NotificationModel {
  final String id;
  final String userId;
  final String type; // follow, like, favorite, tip, comment
  final Sender sender;
  final Song? song;
  final String message;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.sender,
    this.song,
    required this.message,
    this.metadata,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'],
      userId: json['userId'],
      type: json['type'],
      sender: Sender.fromJson(json['senderId']),
      song: json['songId'] != null ? Song.fromJson(json['songId']) : null,
      message: json['message'],
      metadata: json['metadata'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'senderId': sender.toJson(),
      'songId': song?.toJson(),
      'message': message,
      'metadata': metadata,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class Sender {
  final String id;
  final String username;
  final String? email;
  final String? avatarUrl;

  const Sender({
    required this.id,
    required this.username,
    this.email,
    this.avatarUrl,
  });

  factory Sender.fromJson(Map<String, dynamic> json) {
    return Sender(
      id: json['_id'] ?? json['id'],
      username: json['username'],
      email: json['email'],
      avatarUrl: json['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
    };
  }
}

class Song {
  final String id;
  final String title;
  final String? albumArt;

  const Song({
    required this.id,
    required this.title,
    this.albumArt,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      albumArt: json['albumArt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'albumArt': albumArt,
    };
  }
}

/// Mock notifications for testing
class MockNotifications {
  static final List<NotificationModel> notifications = [
    NotificationModel(
      id: '1',
      userId: '6982b4dbb7a73570da690dab',
      type: 'like',
      sender: const Sender(
        id: '2',
        username: 'musiclover23',
        avatarUrl: 'https://i.pravatar.cc/150?img=1',
      ),
      song: const Song(
        id: '1',
        title: 'Neon Dreams',
        albumArt: 'https://picsum.photos/seed/album1/300/300',
      ),
      message: 'musiclover23 liked your song "Neon Dreams"',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    NotificationModel(
      id: '2',
      userId: '6982b4dbb7a73570da690dab',
      type: 'follow',
      sender: const Sender(
        id: '3',
        username: 'john_artist',
        avatarUrl: 'https://i.pravatar.cc/150?img=2',
      ),
      message: 'john_artist started following you',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotificationModel(
      id: '3',
      userId: '6982b4dbb7a73570da690dab',
      type: 'tip',
      sender: const Sender(
        id: '4',
        username: 'generous_fan',
        avatarUrl: 'https://i.pravatar.cc/150?img=3',
      ),
      song: const Song(
        id: '3',
        title: 'Tokyo Nights',
        albumArt: 'https://picsum.photos/seed/album3/300/300',
      ),
      message: 'generous_fan sent you a tip of 50 tokens',
      metadata: {'amount': 5.0},
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    NotificationModel(
      id: '4',
      userId: '6982b4dbb7a73570da690dab',
      type: 'comment',
      sender: const Sender(
        id: '5',
        username: 'critic_mike',
        avatarUrl: 'https://i.pravatar.cc/150?img=4',
      ),
      song: const Song(
        id: '7',
        title: 'Electric Love',
        albumArt: 'https://picsum.photos/seed/album7/300/300',
      ),
      message: 'critic_mike commented on "Electric Love"',
      metadata: {'commentText': 'Amazing track! Love the vibes 🔥'},
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    NotificationModel(
      id: '5',
      userId: '6982b4dbb7a73570da690dab',
      type: 'favorite',
      sender: const Sender(
        id: '6',
        username: 'playlist_queen',
        avatarUrl: 'https://i.pravatar.cc/150?img=5',
      ),
      song: const Song(
        id: '5',
        title: 'Bassline Paradise',
        albumArt: 'https://picsum.photos/seed/album5/300/300',
      ),
      message: 'playlist_queen added "Bassline Paradise" to favorites',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];
}
