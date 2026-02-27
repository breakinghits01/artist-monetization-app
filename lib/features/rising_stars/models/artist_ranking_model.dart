/// Artist ranking data from Rising Stars API
class ArtistRanking {
  final String id;
  final String username;
  final String email;
  final String role;
  final String? avatar;
  final String? bio;
  final int followerCount;
  final int songCount;
  final bool hasExclusiveContent;
  final int recentFollowerCount;
  final int recentLikesCount;
  final int recentCommentsCount;
  final int recentSharesCount;
  final double risingScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ArtistRanking({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.avatar,
    this.bio,
    required this.followerCount,
    required this.songCount,
    required this.hasExclusiveContent,
    this.recentFollowerCount = 0,
    this.recentLikesCount = 0,
    this.recentCommentsCount = 0,
    this.recentSharesCount = 0,
    this.risingScore = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ArtistRanking.fromJson(Map<String, dynamic> json) {
    return ArtistRanking(
      id: json['_id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      avatar: json['avatar'] as String?,
      bio: json['bio'] as String?,
      followerCount: json['followerCount'] as int? ?? 0,
      songCount: json['songCount'] as int? ?? 0,
      hasExclusiveContent: json['hasExclusiveContent'] as bool? ?? false,
      recentFollowerCount: json['recentFollowerCount'] as int? ?? 0,
      recentLikesCount: json['recentLikesCount'] as int? ?? 0,
      recentCommentsCount: json['recentCommentsCount'] as int? ?? 0,
      recentSharesCount: json['recentSharesCount'] as int? ?? 0,
      risingScore: (json['risingScore'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Rising Stars configuration metadata from API
class RisingStarsConfig {
  final String timeWindow;
  final String formula;
  final List<String> availableTimeWindows;
  final List<FormulaInfo> availableFormulas;

  const RisingStarsConfig({
    required this.timeWindow,
    required this.formula,
    required this.availableTimeWindows,
    required this.availableFormulas,
  });

  factory RisingStarsConfig.fromJson(Map<String, dynamic> json) {
    return RisingStarsConfig(
      timeWindow: json['timeWindow'] as String,
      formula: json['formula'] as String,
      availableTimeWindows: (json['availableTimeWindows'] as List)
          .map((e) => e as String)
          .toList(),
      availableFormulas: (json['availableFormulas'] as List)
          .map((e) => FormulaInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Formula information from API
class FormulaInfo {
  final String key;
  final String name;
  final String description;

  const FormulaInfo({
    required this.key,
    required this.name,
    required this.description,
  });

  factory FormulaInfo.fromJson(Map<String, dynamic> json) {
    return FormulaInfo(
      key: json['key'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }
}

/// Pagination metadata
class RankingPagination {
  final int currentPage;
  final int totalPages;
  final int totalArtists;
  final bool hasMore;

  const RankingPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalArtists,
    required this.hasMore,
  });

  factory RankingPagination.fromJson(Map<String, dynamic> json) {
    return RankingPagination(
      currentPage: json['currentPage'] as int,
      totalPages: json['totalPages'] as int,
      totalArtists: json['totalArtists'] as int,
      hasMore: json['hasMore'] as bool,
    );
  }
}

/// Complete Rising Stars API response
class RisingStarsResponse {
  final bool success;
  final List<ArtistRanking> artists;
  final RankingPagination pagination;
  final RisingStarsConfig? risingStarsConfig;

  const RisingStarsResponse({
    required this.success,
    required this.artists,
    required this.pagination,
    this.risingStarsConfig,
  });

  factory RisingStarsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return RisingStarsResponse(
      success: json['success'] as bool,
      artists: (data['artists'] as List)
          .map((e) => ArtistRanking.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: RankingPagination.fromJson(
          data['pagination'] as Map<String, dynamic>),
      risingStarsConfig: data['risingStarsConfig'] != null
          ? RisingStarsConfig.fromJson(
              data['risingStarsConfig'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Time window options for filtering
enum TimeWindow {
  sevenDays('7d', '7 Days', 'Hot/Trending'),
  thirtyDays('30d', '30 Days', 'Rising Stars'),
  ninetyDays('90d', '90 Days', 'Long-term Trending');

  const TimeWindow(this.key, this.label, this.description);

  final String key;
  final String label;
  final String description;

  static TimeWindow fromKey(String key) {
    return TimeWindow.values.firstWhere(
      (w) => w.key == key,
      orElse: () => TimeWindow.thirtyDays,
    );
  }
}

/// Formula options for ranking
enum FormulaType {
  balanced('balanced', 'Balanced', 'All-around engagement'),
  viral('viral', 'Viral', 'Emphasizes shares'),
  engaged('engaged', 'Engaged', 'Emphasizes comments'),
  growth('growth', 'Growth', 'Emphasizes followers');

  const FormulaType(this.key, this.label, this.description);

  final String key;
  final String label;
  final String description;

  static FormulaType fromKey(String key) {
    return FormulaType.values.firstWhere(
      (f) => f.key == key,
      orElse: () => FormulaType.balanced,
    );
  }
}
