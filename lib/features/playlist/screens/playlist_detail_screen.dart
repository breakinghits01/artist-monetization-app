import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../models/playlist_model.dart';
import '../providers/playlists_provider.dart';
import '../../player/models/song_model.dart';
import '../../player/providers/audio_player_provider.dart';
import '../../player/widgets/mini_player.dart';
import '../../player/widgets/player_wrapper.dart';

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final String playlistId;
  final String playlistName;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  ConsumerState<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  PlaylistModel? _playlist;
  List<SongModel> _songs = [];
  bool _isLoading = true;
  String? _error;
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get playlist details with populated songs
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/api/v1/playlists/${widget.playlistId}',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiConfig.tempToken}',
          },
        ),
      );

      if (response.statusCode == 200 && mounted) {
        final responseData = response.data['data']['playlist'] as Map<String, dynamic>;
        
        // Create a mutable copy for modifications
        final data = Map<String, dynamic>.from(responseData);
        
        // Convert _id to id
        if (data['_id'] != null) {
          data['id'] = data['_id'].toString();
        }
        
        // Parse songs separately before creating playlist model
        final List<SongModel> songs = [];
        debugPrint('📋 Parsing playlist songs...');
        debugPrint('Songs data type: ${data['songs'].runtimeType}');
        debugPrint('Songs data: ${data['songs']}');
        
        if (data['songs'] != null && data['songs'] is List) {
          final songsArray = data['songs'] as List;
          debugPrint('📊 Total songs in array: ${songsArray.length}');
          
          for (var songData in songsArray) {
            try {
              debugPrint('🎵 Processing song: ${songData.runtimeType}');
              
              if (songData is Map<String, dynamic>) {
                // Song is populated object
                final songMap = Map<String, dynamic>.from(songData);
                debugPrint('🗺️ Song map keys: ${songMap.keys.toList()}');
                debugPrint('🔑 Song ID: ${songMap['_id'] ?? songMap['id']}');
                
                // Add id field if only _id exists
                if (songMap['_id'] != null && songMap['id'] == null) {
                  songMap['id'] = songMap['_id'];
                }
                
                if (songMap['id'] != null || songMap['_id'] != null) {
                  final song = SongModel.fromJson(songMap);
                  songs.add(song);
                  debugPrint('✅ Added song: ${song.title}');
                } else {
                  debugPrint('⚠️ Skipping song - no ID found');
                }
              } else if (songData is String) {
                // Song is just an ID - skip it
                debugPrint('⚠️ Song is just ID: $songData (not populated)');
                continue;
              }
            } catch (e, stackTrace) {
              debugPrint('❌ Error parsing song: $e');
              debugPrint('Stack trace: $stackTrace');
            }
          }
        }
        
        debugPrint('🎵 Parsed ${songs.length} songs successfully');
        
        // Convert songs array to IDs for playlist model
        data['songs'] = (data['songs'] as List?)
            ?.map((s) {
              if (s is Map) return s['_id']?.toString() ?? '';
              if (s is String) return s;
              return '';
            })
            .where((id) => id.isNotEmpty)
            .toList() ?? [];
        
        final playlist = PlaylistModel.fromJson(data);
        
        setState(() {
          _playlist = playlist;
          _songs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _playSong(SongModel song) {
    ref.read(audioPlayerProvider.notifier).playSong(song);
  }

  Future<void> _removeSong(String songId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Song'),
        content: const Text('Remove this song from the playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ref.read(playlistsProvider.notifier).removeSongFromPlaylist(
              widget.playlistId,
              songId,
            );
        _loadPlaylist(); // Reload playlist
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Song removed from playlist'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentSong = ref.watch(currentSongProvider);
    final hasSong = currentSong != null;

    return PlayerWrapper(
      child: Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
        slivers: [
          // App bar with playlist info
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.8),
                      theme.colorScheme.secondary.withOpacity(0.9),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Playlist icon
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.playlist_play,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Playlist name
                        Text(
                          _playlist?.name ?? widget.playlistName,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Description & song count
                        if (_playlist?.description != null) ...[
                          Text(
                            _playlist!.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          '${_playlist?.songCount ?? 0} songs',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $_error'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loadPlaylist,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_playlist == null || _songs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_note,
                      size: 80,
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No songs in this playlist',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add songs to get started',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = _songs[index];
                  return _buildSongTile(song, theme, isDark);
                },
                childCount: _songs.length,
              ),
            ),
          
          // Add bottom padding for mini player
          if (hasSong)
            const SliverToBoxAdapter(
              child: SizedBox(height: 90),
            ),
        ],
      ),
      
      // Mini player at bottom
      if (hasSong)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            child: const MiniPlayer(),
          ),
        ),
        ],
      ),
      ),
    );
  }

  Widget _buildSongTile(SongModel song, ThemeData theme, bool isDark) {
    final currentSong = ref.watch(currentSongProvider);
    final playerState = ref.watch(audioPlayerProvider);
    final isCurrentSong = currentSong?.id == song.id;
    final isPlaying = isCurrentSong && playerState.isPlaying;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Stack(
          alignment: Alignment.center,
          children: [
            // Album art
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: song.albumArt != null
                  ? CachedNetworkImage(
                      imageUrl: song.albumArt!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 56,
                        height: 56,
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        child: const Icon(Icons.music_note, size: 24),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 56,
                        height: 56,
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        child: const Icon(Icons.music_note, size: 24),
                      ),
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.music_note, color: Colors.white, size: 28),
                    ),
            ),
            // Playing indicator
            if (isPlaying)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.equalizer,
                  color: Colors.white,
                  size: 28,
                ),
              ),
          ],
        ),
        title: Text(
          song.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isCurrentSong ? theme.colorScheme.primary : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          song.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showSongOptions(song),
        ),
        onTap: () => _playSong(song),
      ),
    );
  }

  void _showSongOptions(SongModel song) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.play_circle, color: theme.colorScheme.primary),
                title: const Text('Play'),
                onTap: () {
                  Navigator.pop(context);
                  _playSong(song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
                title: const Text('Remove from Playlist', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _removeSong(song.id);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
