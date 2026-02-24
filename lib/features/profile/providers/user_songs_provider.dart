import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../../../core/config/api_config.dart';
import '../../../core/services/storage_service.dart';
import '../../player/models/song_model.dart';
import '../../auth/providers/auth_provider.dart';

/// User songs state
class UserSongsState {
  final List<SongModel> songs;
  final bool isLoading;
  final String? error;

  const UserSongsState({
    this.songs = const [],
    this.isLoading = false,
    this.error,
  });

  UserSongsState copyWith({
    List<SongModel>? songs,
    bool? isLoading,
    String? error,
  }) {
    return UserSongsState(
      songs: songs ?? this.songs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// User songs provider - fetches from backend with local cache
final userSongsProvider = StateNotifierProvider<UserSongsNotifier, UserSongsState>((ref) {
  return UserSongsNotifier(ref);
});

class UserSongsNotifier extends StateNotifier<UserSongsState> {
  static const String _storageKey = 'user_uploaded_songs_cache';
  static const String _oldStorageKey = 'user_uploaded_songs'; // Old key for migration
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
  final StorageService _storage = StorageService();
  final Ref _ref;
  
  UserSongsNotifier(this._ref) : super(const UserSongsState()) {
    _migrateOldCache();
    _loadFromBackend();
  }

  /// Migrate songs from old cache key to new key
  Future<void> _migrateOldCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final oldCacheExists = prefs.containsKey(_oldStorageKey);
      final newCacheExists = prefs.containsKey(_storageKey);
      
      if (oldCacheExists && !newCacheExists) {
        print('📦 Migrating songs from old cache...');
        final oldData = prefs.getString(_oldStorageKey);
        if (oldData != null) {
          await prefs.setString(_storageKey, oldData);
          await prefs.remove(_oldStorageKey);
          print('✅ Migration complete');
        }
      }
    } catch (e) {
      print('⚠️ Cache migration failed: $e');
    }
  }

  /// Load songs from backend (primary source - REQUIRED)
  Future<void> _loadFromBackend() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Get actual user ID from auth provider
      final currentUser = _ref.read(currentUserProvider);
      final userId = currentUser?['_id'] ?? currentUser?['id'];
      
      if (userId == null) {
        print('⚠️ No user ID found - user not logged in');
        state = state.copyWith(isLoading: false, songs: []);
        return;
      }
      
      // STEP 1: Load cache first for instant UI
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_storageKey);
      if (cachedJson != null) {
        try {
          final List<dynamic> songsList = jsonDecode(cachedJson);
          final cachedSongs = songsList.map((json) => _parseSong(json)).toList();
          state = state.copyWith(
            songs: cachedSongs,
            isLoading: false,
          );
          print('📦 Loaded ${cachedSongs.length} songs from cache (instant)');
        } catch (e) {
          print('⚠️ Cache parse error: $e');
        }
      }
      
      // STEP 2: Fetch from network in background
      final endpoint = '${ApiConfig.songsEndpoint}/artist/$userId';
      print('🌐 Fetching songs from database: ${ApiConfig.baseUrl}$endpoint');
      print('👤 User ID: $userId');
      
      // Get actual user token (may fail if Keystore unavailable)
      String? token;
      try {
        token = await _storage.getAccessToken();
      } catch (e) {
        print('⚠️ Keystore error when reading token: $e');
        // Keep cached data, skip network update
        return;
      }
      
      if (token == null) {
        print('⚠️ No auth token found - using cached data');
        // Keep cached data, skip network update
        return;
      }
      
      final response = await _dio.get(
        endpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
          },
        ),
        queryParameters: {
          '_t': DateTime.now().millisecondsSinceEpoch, // Cache buster
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Parse response - handle different formats
        List<dynamic> songsList = [];
        if (data is Map) {
          if (data['success'] == true) {
            if (data['data'] is Map && data['data']['songs'] != null) {
              songsList = data['data']['songs'] as List;
            } else if (data['data'] is List) {
              songsList = data['data'] as List;
            } else if (data['songs'] != null) {
              songsList = data['songs'] as List;
            }
          }
        } else if (data is List) {
          songsList = data;
        }
        
        final songs = songsList.map((json) => _parseSong(json)).toList();
        state = state.copyWith(songs: songs, isLoading: false, error: null);
        
        // Save to cache for offline viewing only
        await _saveToCache(songs);
        print('✅ Loaded ${songs.length} songs from database');
      } else {
        throw Exception('Unexpected status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // User has no songs yet - this is normal for new users
        print('ℹ️ No songs found in database (new user)');
        state = state.copyWith(songs: [], isLoading: false, error: null);
        await clearCache(); // Clear stale cache
      } else {
        print('⚠️ Cannot connect to database: ${e.message}');
        print('📦 Loading from offline cache (data may be outdated)');
        
        // Load from cache and ensure state is updated
        final prefs = await SharedPreferences.getInstance();
        final songsJson = prefs.getString(_storageKey);
        
        if (songsJson != null) {
          try {
            final List<dynamic> songsList = jsonDecode(songsJson);
            final songs = songsList.map((json) => _parseSong(json)).toList();
            state = state.copyWith(
              songs: songs,
              isLoading: false,
              error: null, // Don't show error if we have cached data
            );
            print('📦 Loaded ${songs.length} songs from cache');
          } catch (cacheError) {
            print('❌ Error parsing cache: $cacheError');
            state = state.copyWith(
              songs: [],
              isLoading: false,
              error: 'Offline - no cached data available'
            );
          }
        } else {
          print('❌ No cached songs available');
          state = state.copyWith(
            songs: [],
            isLoading: false,
            error: 'Offline - no cached data available'
          );
        }
      }
    } catch (e) {
      print('❌ Error loading from database: $e');
      print('📦 Falling back to cache');
      
      // Load from cache and ensure state is updated
      final prefs = await SharedPreferences.getInstance();
      final songsJson = prefs.getString(_storageKey);
      
      if (songsJson != null) {
        try {
          final List<dynamic> songsList = jsonDecode(songsJson);
          final songs = songsList.map((json) => _parseSong(json)).toList();
          state = state.copyWith(
            songs: songs,
            isLoading: false,
            error: null, // Don't show error if we have cached data
          );
          print('📦 Loaded ${songs.length} songs from cache');
        } catch (cacheError) {
          print('❌ Error parsing cache: $cacheError');
          state = state.copyWith(
            songs: [],
            isLoading: false,
            error: 'Offline - no cached data available'
          );
        }
      } else {
        print('❌ No cached songs available');
        state = state.copyWith(
          songs: [],
          isLoading: false,
          error: 'Offline - no cached data available'
        );
      }
    }
  }

  /// Save to cache for offline access
  Future<void> _saveToCache(List<SongModel> songs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final songsJson = jsonEncode(
        songs.map((song) => _songToJson(song)).toList(),
      );
      await prefs.setString(_storageKey, songsJson);
    } catch (e) {
      print('❌ Error saving to cache: $e');
    }
  }

  /// Refresh songs from backend
  Future<void> refresh() async {
    print('🔄 Refreshing songs from backend...');
    await _loadFromBackend();
  }

  /// Add a new song (optimistic update, then refresh from database)
  Future<void> addSong(SongModel song) async {
    // Show in UI immediately (optimistic update)
    final updatedSongs = [song, ...state.songs];
    state = state.copyWith(songs: updatedSongs);
    print('✅ Song added to UI: ${song.title}');
    
    // Refresh from database to get real data
    print('🔄 Refreshing from database to confirm...');
    await Future.delayed(const Duration(milliseconds: 500));
    await refresh();
  }

  /// Clear cache (for testing)
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    print('🗑️ Cache cleared');
  }

  /// Parse song from API response
  SongModel _parseSong(Map<String, dynamic> json) {
    // Backend populates artistId with user data (username, email, avatarUrl)
    final artistData = json['artistId'];
    final artistName = artistData is Map<String, dynamic> 
        ? (artistData['username'] as String?) 
        : null;
    final artistIdValue = artistData is Map<String, dynamic>
        ? (artistData['_id'] as String?)
        : (artistData as String?);
    
    return SongModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? 'Untitled',
      artist: artistName ?? json['artistName'] ?? 'Current User',
      artistId: artistIdValue ?? '',
      albumArt: json['coverArt'] ?? json['albumArt'] ?? 'https://via.placeholder.com/300',
      duration: Duration(seconds: json['duration'] ?? 180),
      audioUrl: json['fileUrl'] ?? json['audioUrl'] ?? '',
      genre: json['genre'] ?? 'Unknown',
      tokenReward: json['price'] ?? json['tokenReward'] ?? 10,
      playCount: json['playCount'] ?? 0,
      likeCount: json['likeCount'] ?? 0,
      dislikeCount: json['dislikeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      shareCount: json['shareCount'] ?? 0,
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      ratingCount: json['ratingCount'] ?? 0,
    );
  }

  /// Update play count for a specific song in real-time
  void updateSongPlayCount(String songId, int newPlayCount) {
    final updatedSongs = state.songs.map((song) {
      if (song.id == songId) {
        return SongModel(
          id: song.id,
          title: song.title,
          artistId: song.artistId,
          artist: song.artist,
          audioUrl: song.audioUrl,
          duration: song.duration,
          tokenReward: song.tokenReward,
          albumArt: song.albumArt,
          genre: song.genre,
          playCount: newPlayCount, // Update with new count
        );
      }
      return song;
    }).toList();

    state = state.copyWith(songs: updatedSongs);
    print('✅ Updated song $songId play count to $newPlayCount in user songs list');
  }

  /// Convert song to JSON
  Map<String, dynamic> _songToJson(SongModel song) {
    return {
      'id': song.id,
      'title': song.title,
      'artist': song.artist,
      'artistId': song.artistId,
      'albumArt': song.albumArt,
      'duration': song.duration.inSeconds,
      'audioUrl': song.audioUrl,
      'genre': song.genre,
      'tokenReward': song.tokenReward,
      'playCount': song.playCount,
      'likeCount': song.likeCount,
      'dislikeCount': song.dislikeCount,
      'commentCount': song.commentCount,
      'shareCount': song.shareCount,
      'averageRating': song.averageRating,
      'ratingCount': song.ratingCount,
    };
  }
}
