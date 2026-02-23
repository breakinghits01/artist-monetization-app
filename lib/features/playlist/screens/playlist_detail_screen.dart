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
import '../../player/widgets/audio_wave_indicator.dart';
import '../../../services/providers/playlist_download_provider.dart';
import '../../../services/providers/offline_download_provider.dart';
import '../../../services/offline_download_manager.dart';

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
                debugPrint('🎵 Audio URL: ${songMap['audioUrl']}');
                debugPrint('🎤 Artist: ${songMap['artistId']}');
                
                // Add id field if only _id exists
                if (songMap['_id'] != null && songMap['id'] == null) {
                  songMap['id'] = songMap['_id'];
                }
                
                // Check if song has required fields
                if ((songMap['id'] != null || songMap['_id'] != null) && songMap['audioUrl'] != null) {
                  try {
                    final song = SongModel.fromJson(songMap);
                    songs.add(song);
                    debugPrint('✅ Added song: ${song.title} - ${song.audioUrl}');
                  } catch (e, stack) {
                    debugPrint('❌ Error creating SongModel: $e');
                    debugPrint('Stack: $stack');
                  }
                } else {
                  debugPrint('⚠️ Skipping song - missing required fields (ID: ${songMap['_id']}, audioUrl: ${songMap['audioUrl']})');
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
    // Play song with full playlist as queue
    if (_songs.isNotEmpty) {
      ref.read(audioPlayerProvider.notifier).playSongWithQueue(song, _songs);
    } else {
      ref.read(audioPlayerProvider.notifier).playSong(song);
    }
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
          // App bar with playlist cover
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.surface.withValues(alpha: 0.95),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Playlist cover art
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.secondary,
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.playlist_play,
                                color: Colors.white,
                                size: 80,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Playlist name
                        Text(
                          _playlist?.name ?? widget.playlistName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Song count
                        Text(
                          '${_playlist?.songCount ?? 0} songs',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
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
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: _buildActionButtons(theme),
              ),
            ),
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

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        // Playlist cover thumbnail
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
              ),
              child: const Icon(
                Icons.playlist_play,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        
        // Add to library icon
        IconButton(
          onPressed: () {
            // TODO: Add to library
          },
          icon: const Icon(Icons.add_circle_outline, size: 28),
          tooltip: 'Add to library',
        ),
        const SizedBox(width: 4),
        
        // Download icon
        if (!kIsWeb)
          _buildDownloadIcon(theme),
        if (!kIsWeb) const SizedBox(width: 4),
        
        // More options
        IconButton(
          onPressed: () => _showPlaylistOptions(theme),
          icon: const Icon(Icons.more_vert, size: 28),
          tooltip: 'More options',
        ),
        
        const Spacer(),
        
        // Shuffle icon
        IconButton(
          onPressed: _songs.isEmpty ? null : () {
            final shuffled = List<SongModel>.from(_songs)..shuffle();
            ref.read(audioPlayerProvider.notifier).playSongWithQueue(
              shuffled.first,
              shuffled,
            );
          },
          icon: const Icon(Icons.shuffle, size: 28),
          tooltip: 'Shuffle',
        ),
        const SizedBox(width: 12),
        
        // Large circular play button (Spotify style)
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: _songs.isEmpty ? null : () {
              ref.read(audioPlayerProvider.notifier).playSongWithQueue(
                _songs.first,
                _songs,
              );
            },
            icon: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadIcon(ThemeData theme) {
    final downloadState = ref.watch(playlistDownloadStateProvider(widget.playlistId));
    final songIds = _songs.map((s) => s.id).toList();
    final isFullyDownloaded = ref.watch(playlistDownloadedProvider(songIds));

    if (downloadState?.isDownloading == true) {
      // Show animated progress with circular indicator
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                value: downloadState!.progress,
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
            Text(
              '${(downloadState.progress * 100).toInt()}%',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      );
    } else if (isFullyDownloaded) {
      // Downloaded - show checkmark with colored background
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.green.withValues(alpha: 0.15),
        ),
        child: IconButton(
          onPressed: () => _showDownloadOptions(theme, songIds),
          icon: const Icon(
            Icons.check_circle,
            size: 28,
            color: Colors.green,
          ),
          tooltip: 'Downloaded',
          padding: EdgeInsets.zero,
        ),
      );
    } else {
      // Not downloaded - regular download icon
      return IconButton(
        onPressed: () async {
          // Get download state after completion to show accurate count
          final success = await ref.read(playlistDownloadProvider.notifier).downloadPlaylist(
            widget.playlistId,
            _songs,
          );
          
          if (mounted) {
            // Get the final state to show accurate downloaded count
            final downloadState = ref.read(playlistDownloadProvider)[widget.playlistId];
            final downloadedCount = downloadState?.downloadedCount ?? 0;
            
            String message;
            if (success) {
              if (downloadedCount == 0) {
                message = 'All songs already downloaded';
              } else if (downloadedCount == _songs.length) {
                message = 'Downloaded $downloadedCount song${downloadedCount > 1 ? 's' : ''}';
              } else {
                final skipped = _songs.length - downloadedCount;
                message = 'Downloaded $downloadedCount new song${downloadedCount > 1 ? 's' : ''} ($skipped already saved)';
              }
            } else {
              message = downloadState?.error ?? 'Some songs failed to download';
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: success ? Colors.green : Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        icon: const Icon(Icons.download_outlined, size: 28),
        tooltip: 'Download playlist',
      );
    }
  }

  void _showDownloadOptions(ThemeData theme, List<String> songIds) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Downloaded'),
              subtitle: Text('${_songs.length} songs available offline'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Downloads'),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Downloads'),
                    content: const Text('Remove all downloaded songs from this playlist?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  await ref.read(playlistDownloadProvider.notifier).deletePlaylistDownloads(songIds);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Downloads deleted'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaylistOptions(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Playlist'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to edit screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Playlist'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Share functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Playlist', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Playlist'),
                    content: const Text('Are you sure you want to delete this playlist?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  // TODO: Delete playlist
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Playlist deleted'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
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
                      memCacheHeight: 150,
                      memCacheWidth: 150,
                      placeholder: (context, url) => Container(
                        width: 56,
                        height: 56,
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        child: const Icon(Icons.music_note, size: 24),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 56,
                        height: 56,
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
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
            // Playing indicator with wave animation
            if (isCurrentSong)
              _PlayingIndicatorOverlay(isPlaying: isPlaying),
          ],
        ),
        title: Text(
          song.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: isCurrentSong ? theme.colorScheme.primary : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                song.artist,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.headphones,
              size: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(width: 4),
            Text(
              '${song.playCount}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
            // Downloaded indicator
            if (!kIsWeb)
              Consumer(
                builder: (context, ref, child) {
                  final status = ref.watch(songDownloadStatusProvider(song.id));
                  if (status == OfflineDownloadStatus.downloaded) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Colors.green,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
          ],
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
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
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

/// Playing indicator overlay with animated wave and hover pause button
class _PlayingIndicatorOverlay extends ConsumerStatefulWidget {
  final bool isPlaying;
  
  const _PlayingIndicatorOverlay({required this.isPlaying});

  @override
  ConsumerState<_PlayingIndicatorOverlay> createState() => _PlayingIndicatorOverlayState();
}

class _PlayingIndicatorOverlayState extends ConsumerState<_PlayingIndicatorOverlay> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(audioPlayerProvider);
    
    return Positioned.fill(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black.withValues(alpha: _isHovered ? 0.5 : 0.3),
          ),
          child: Stack(
            children: [
              // Show animated wave when playing, static play icon when paused
              if (!_isHovered || !kIsWeb)
                Center(
                  child: playerState.isPlaying
                      ? AudioWaveIndicator(
                          isPlaying: true,
                          color: Colors.white,
                          size: 32,
                        )
                      : Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                ),
              // Pause button (only on hover for web, or always for mobile)
              if (_isHovered && kIsWeb)
                Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        ref.read(audioPlayerProvider.notifier).playPause();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          playerState.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
