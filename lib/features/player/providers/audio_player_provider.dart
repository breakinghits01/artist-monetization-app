import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../models/song_model.dart';
import '../models/player_state.dart' as models;
import '../../home/providers/wallet_provider.dart';
import '../../../core/config/api_config.dart';
import 'queue_provider.dart';
import '../services/audio_service_handler.dart';
import '../../discover/services/song_api_service.dart';
import '../../profile/providers/user_songs_provider.dart';
import '../../discover/providers/song_provider.dart';
import '../../../services/providers/offline_download_provider.dart';

/// Current song provider
final currentSongProvider = StateProvider<SongModel?>((ref) => null);

/// Player expanded state
final playerExpandedProvider = StateProvider<bool>((ref) => false);

/// Playing from download provider (shows if current song is from local file)
final playingFromDownloadProvider = StateProvider<bool>((ref) => false);

/// Audio player provider - kept alive for app lifetime, manual cleanup available
final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerNotifier, models.PlayerState>(
      (ref) {
        final notifier = AudioPlayerNotifier(ref);
        return notifier;
      },
    );

/// Token earn state provider
final tokenEarnProvider =
    StateNotifierProvider<TokenEarnNotifier, models.TokenEarnState>(
      (ref) => TokenEarnNotifier(ref),
    );

class AudioPlayerNotifier extends StateNotifier<models.PlayerState> {
  final Ref _ref;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<StreamSubscription> _subscriptions = [];
  AudioServiceHandler? _audioServiceHandler;
  bool _hasRewardedCurrentSong = false;
  bool _hasIncrementedPlayCount = false;
  bool _isDisposed = false;

  AudioPlayerNotifier(this._ref) : super(const models.PlayerState()) {
    _initPlayer();
    _initAudioService();
    _configureOptimalPlayback();
  }
  
  /// Configure optimal playback settings for Cloudflare R2
  Future<void> _configureOptimalPlayback() async {
    try {
      // OPTIMIZATION: Disable automatic stalling to start playback faster
      // Cloudflare R2 has fast CDN delivery, so we don't need to wait for large buffer
      await _audioPlayer.setAutomaticallyWaitsToMinimizeStalling(false);
      print('✅ Audio player configured for fast CDN playback');
    } catch (e) {
      print('⚠️ Could not configure optimal playback (non-critical): $e');
    }
  }

  Future<void> _initAudioService() async {
    // On iOS, JustAudioBackground handles lockscreen via MPRemoteCommandCenter
    // On Android, use AudioService for custom notification
    // Skip on web (no native audio service needed)
    if (!kIsWeb && Platform.isAndroid) {
      try {
        print('🔧 Initializing audio service for Android...');
        _audioServiceHandler = await initAudioService(_audioPlayer);
        _audioServiceHandler!.onSkipToNext = () => playNext();
        _audioServiceHandler!.onSkipToPrevious = () => playPrevious();
        print('✅ Audio service initialized with custom controls');
      } catch (e) {
        print('⚠️ Audio service init failed: $e');
        // Continue without audio service - music will still play
      }
    } else {
      print('📱 iOS: Using JustAudioBackground for lockscreen controls');
    }
  }

  void _initPlayer() {
    // Listen to position changes
    _subscriptions.add(
      _audioPlayer.positionStream.listen((position) {
        if (!_isDisposed) {
          state = state.copyWith(position: position);
          _checkTokenEligibility(position);
        }
      }),
    );

    // Listen to duration changes
    _subscriptions.add(
      _audioPlayer.durationStream.listen((duration) {
        if (!_isDisposed && duration != null) {
          state = state.copyWith(duration: duration);
        }
      }),
    );

    // Listen to player state changes
    _subscriptions.add(
      _audioPlayer.playerStateStream.listen((playerState) {
        if (!_isDisposed) {
          state = state.copyWith(
            isPlaying: playerState.playing,
            isLoading: playerState.processingState == ProcessingState.loading,
          );

          // Auto-play next song when current ends
          if (playerState.processingState == ProcessingState.completed) {
            _onSongCompleted();
          }
        }
      }),
    );

    // Listen to buffering state
    _subscriptions.add(
      _audioPlayer.bufferedPositionStream.listen((buffered) {
        if (!_isDisposed) {
          final isBuffering =
              buffered < state.position &&
              _audioPlayer.processingState == ProcessingState.buffering;
          state = state.copyWith(isBuffering: isBuffering);
        }
      }),
    );
    
    // CRITICAL: Listen to current index changes (lockscreen skip sync)
    // This is the SINGLE SOURCE OF TRUTH for queue position
    // All track changes (next, previous, lockscreen) flow through here
    _subscriptions.add(
      _audioPlayer.currentIndexStream.listen((index) {
        if (!_isDisposed && index != null) {
          final queueState = _ref.read(queueProvider);
          if (index >= 0 && index < queueState.queue.length) {
            final newSong = queueState.queue[index];
            
            // Update current song in provider
            _ref.read(currentSongProvider.notifier).state = newSong;
            
            // Update queue index (single source of truth)
            _ref.read(queueProvider.notifier).setCurrentIndex(index);
            
            // Reset tracking flags when track changes
            _hasRewardedCurrentSong = false;
            _hasIncrementedPlayCount = false;
            _ref.read(tokenEarnProvider.notifier).reset();
            
            // Start play session for track changes (fire and forget)
            // Note: This is safe because backend validates session age
            _startPlaySessionForCurrentSong(newSong.id);
            
            // Update Android notification with new song metadata
            if (_audioServiceHandler != null) {
              _audioServiceHandler!.updateQueueIndex(index);
              
              // Get album art for the new song
              String? albumArtUrl;
              if (newSong.albumArt != null && 
                  newSong.albumArt!.isNotEmpty &&
                  !newSong.albumArt!.contains('placeholder') &&
                  !newSong.albumArt!.contains('picsum.photos') &&
                  !newSong.albumArt!.startsWith('data:')) { // Skip data URIs for Android
                // Support http/https URLs only
                albumArtUrl = newSong.albumArt!.startsWith('http')
                    ? newSong.albumArt!
                    : '${ApiConfig.baseUrl}${newSong.albumArt}';
              }
              
              _audioServiceHandler!.setMediaItem(newSong, artUri: albumArtUrl);
            }
            
            print('🔄 Synced to track $index: ${newSong.title}');
          }
        }
      }),
    );
  }
  
  /// Start play session for current song (fire and forget)
  void _startPlaySessionForCurrentSong(String songId) {
    try {
      final apiService = _ref.read(songApiServiceProvider);
      apiService.startPlaySession(songId).then((_) {
        print('✅ Play session started for song: $songId');
      }).catchError((error) {
        print('⚠️ Failed to start play session (non-critical): $error');
      });
    } catch (e) {
      print('⚠️ Error starting play session: $e');
    }
  }

  /// Play a song
  Future<void> playSong(SongModel song) async {
    if (_isDisposed) {
      print('⚠️ Cannot play song - player is disposed');
      return;
    }
    
    try {
      print('🎵 Starting to play: ${song.title} - ${song.audioUrl}');
      state = state.copyWith(isLoading: true);
      _ref.read(currentSongProvider.notifier).state = song;
      _hasRewardedCurrentSong = false;
      _hasIncrementedPlayCount = false;

      // Reset token earn state
      _ref.read(tokenEarnProvider.notifier).reset();

      // Stop current playback first
      await _audioPlayer.stop();

      // Check for offline downloaded file first
      // Pre-decrypt while app is in foreground (before potential backgrounding)
      // This prevents Android Keystore access errors when app is backgrounded
      String? localFilePath;
      bool isPlayingFromDownload = false;
      
      try {
        final offlineDownloadNotifier = _ref.read(offlineDownloadStateProvider.notifier);
        // Get the decrypted file path for playback (decrypts if needed)
        localFilePath = await offlineDownloadNotifier.getDecryptedFilePath(song.id);
        
        if (localFilePath != null && await File(localFilePath).exists()) {
          print('📦 Playing from decrypted offline file: $localFilePath');
          isPlayingFromDownload = true;
          _ref.read(playingFromDownloadProvider.notifier).state = true;
        } else {
          print('🌐 Streaming from network');
          _ref.read(playingFromDownloadProvider.notifier).state = false;
        }
      } catch (e) {
        print('⚠️ Error checking offline download: $e');
        _ref.read(playingFromDownloadProvider.notifier).state = false;
      }

      // Start play session for backend tracking (only for streaming)
      if (!isPlayingFromDownload) {
        try {
          final apiService = _ref.read(songApiServiceProvider);
          await apiService.startPlaySession(song.id);
          print('✅ Play session started for: ${song.id}');
        } catch (e) {
          print('⚠️ Failed to start play session (non-critical): $e');
          // Continue playback even if session start fails
        }
      } else {
        print('📦 Playing from offline storage - skipping play session tracking');
      }
      
      print('🔗 Loading audio source...');
      
      // Determine audio URL (local file or network stream)
      String audioUrl;
      if (isPlayingFromDownload && localFilePath != null) {
        audioUrl = localFilePath;
        print('📦 Using local file: $audioUrl');
      } else {
        // Convert relative URLs to absolute URLs for network streaming
        audioUrl = song.audioUrl;
        if (!audioUrl.startsWith('http')) {
          // Relative URL - prepend base URL
          audioUrl = '${ApiConfig.baseUrl}$audioUrl';
          print('🔗 Converted to absolute URL: $audioUrl');
        } else {
          print('🔗 Using provided absolute URL: $audioUrl');
        }
      }
      
      print('🔗 Final URL: $audioUrl');
      if (!isPlayingFromDownload) {
        print('🔗 Base URL from config: ${ApiConfig.baseUrl}');
      }
      
      // Prepare album art URL - filter out placeholder URLs and data URIs
      String? albumArtUrl;
      if (song.albumArt != null && 
          !song.albumArt!.contains('placeholder') &&
          !song.albumArt!.contains('picsum.photos') &&
          !song.albumArt!.startsWith('data:')) { // Skip data URIs for Android
        // Support http/https URLs only
        albumArtUrl = song.albumArt!.startsWith('http')
            ? song.albumArt
            : '${ApiConfig.baseUrl}${song.albumArt}';
      }
      
      // Ensure audio service is initialized before setting metadata
      if (_audioServiceHandler == null) {
        print('⏳ Waiting for audio service initialization...');
        await _initAudioService();
      }
      
      // Set lock screen metadata BEFORE loading audio (prevents "Unknown" display)
      if (_audioServiceHandler != null) {
        try {
          await _audioServiceHandler!.setMediaItem(song, artUri: albumArtUrl);
          print('✅ Lock screen metadata set BEFORE playback');
        } catch (e) {
          print('⚠️ Failed to set lock screen metadata: $e');
        }
      } else {
        print('⚠️ Audio service not available - lockscreen will show "Unknown"');
      }
      
      // Load audio and start playback with iOS lockscreen metadata
      try {
        print('🎧 Setting audio source: $audioUrl');
        
        // CRITICAL for iOS: Use AudioSource with MediaItem tag (not setUrl)
        final audioSource = isPlayingFromDownload
            ? AudioSource.file(
                audioUrl,
                tag: MediaItem(
                  id: song.id,
                  title: song.title, // REQUIRED: Must be non-empty
                  artist: song.artist, // REQUIRED: Must be non-empty  
                  album: 'Breaking Hits',
                  duration: song.duration,
                  artUri: albumArtUrl != null ? Uri.parse(albumArtUrl) : null,
                ),
              )
            : AudioSource.uri(
                Uri.parse(audioUrl),
                tag: MediaItem(
                  id: song.id,
                  title: song.title, // REQUIRED: Must be non-empty
                  artist: song.artist, // REQUIRED: Must be non-empty  
                  album: 'Breaking Hits',
                  duration: song.duration,
                  artUri: albumArtUrl != null ? Uri.parse(albumArtUrl) : null,
                ),
              );
        
        // OPTIMIZATION: Set initialPosition to 0 and preload=false for faster start
        // This starts playback immediately without waiting for full buffer
        await _audioPlayer.setAudioSource(
          audioSource,
          initialPosition: Duration.zero,
          preload: true, // Preload to get duration, but play() won't wait
        );
        
        if (isPlayingFromDownload) {
          print('▶️ Starting playback from downloaded file (instant)...');
        } else {
          print('▶️ Starting playback from network (optimized)...');
        }
        // Play immediately - just_audio will handle buffering in background
        await _audioPlayer.play();
        print('✅ Audio player started with fast playback');
      } catch (e) {
        print('❌ Error loading audio URL: $e');
        print('🔗 Failed URL: $audioUrl');
        rethrow;
      }

      // Clear loading state - playing state updated by playerStateStream listener
      state = state.copyWith(
        isLoading: false,
      );
      
      print('✅ Playback started with lock screen controls');
    } catch (e) {
      print('❌ Error playing song: $e');
      state = state.copyWith(isLoading: false, isPlaying: false);
      // Show error to user
      // TODO: Add proper error notification
    }
  }

  /// Play a song with queue context (creates queue from list)
  Future<void> playSongWithQueue(
    SongModel song, 
    List<SongModel> allSongs,
  ) async {
    if (_isDisposed) {
      print('⚠️ Cannot play with queue - player is disposed');
      return;
    }
    
    try {
      print('📋 Playing with queue: ${allSongs.length} songs');
      
      // Reset tracking flags
      _hasRewardedCurrentSong = false;
      _hasIncrementedPlayCount = false;
      _ref.read(currentSongProvider.notifier).state = song;

      // Reset token earn state
      _ref.read(tokenEarnProvider.notifier).reset();

      // Check if song is downloaded (offline)
      bool isPlayingFromDownload = false;
      try {
        final offlineDownloadNotifier = _ref.read(offlineDownloadStateProvider.notifier);
        final localFilePath = await offlineDownloadNotifier.getDecryptedFilePath(song.id);
        
        if (localFilePath != null && await File(localFilePath).exists()) {
          print('📦 Playing from decrypted offline file');
          isPlayingFromDownload = true;
          _ref.read(playingFromDownloadProvider.notifier).state = true;
        } else {
          _ref.read(playingFromDownloadProvider.notifier).state = false;
        }
      } catch (e) {
        print('⚠️ Error checking offline download: $e');
        _ref.read(playingFromDownloadProvider.notifier).state = false;
      }

      // Start play session for backend tracking (only for streaming)
      if (!isPlayingFromDownload) {
        try {
          final apiService = _ref.read(songApiServiceProvider);
          await apiService.startPlaySession(song.id);
          print('✅ Play session started for: ${song.id}');
        } catch (e) {
          print('⚠️ Failed to start play session (non-critical): $e');
          // Continue playback even if session start fails
        }
      } else {
        print('📦 Playing from offline storage - skipping play session tracking');
      }
      
      // Find song index in list
      final songIndex = allSongs.indexWhere((s) => s.id == song.id);
      final startIndex = songIndex >= 0 ? songIndex : 0;
      
      // Set queue in provider
      _ref.read(queueProvider.notifier).setQueue(
        allSongs,
        startIndex: startIndex,
      );
      
      // Pre-decrypt all offline songs in queue BEFORE building audio sources
      // This ensures decryption happens while app is in foreground (before backgrounding)
      // Critical for background playback: Android Keystore doesn't allow background access
      print('🔓 Pre-decrypting offline songs for background playback...');
      final offlineDownloadNotifier = _ref.read(offlineDownloadStateProvider.notifier);
      final Map<String, String> decryptedPaths = {};
      
      for (final s in allSongs) {
        if (offlineDownloadNotifier.isDownloaded(s.id)) {
          final decryptedPath = await offlineDownloadNotifier.getDecryptedFilePath(s.id);
          if (decryptedPath != null && await File(decryptedPath).exists()) {
            decryptedPaths[s.id] = decryptedPath;
            print('✅ Pre-decrypted: ${s.title}');
          }
        }
      }
      print('🔓 Pre-decryption complete: ${decryptedPaths.length}/${allSongs.length} songs offline');
      
      // Build audio sources for entire queue using pre-decrypted paths
      final List<AudioSource> audioSources = [];
      
      for (final s in allSongs) {
        String audioUrl;
        
        // Use pre-decrypted path if available (already decrypted above)
        if (decryptedPaths.containsKey(s.id)) {
          audioUrl = decryptedPaths[s.id]!;
          print('📦 Queue: Using pre-decrypted offline file for ${s.title}');
        } else {
          // Use network stream
          audioUrl = s.audioUrl.startsWith('http')
              ? s.audioUrl
              : '${ApiConfig.baseUrl}${s.audioUrl}';
          print('🌐 Queue: Using network stream for ${s.title}');
        }
        
        // Filter out placeholder images and data URIs (data URIs don't work in Android notifications)
        String? albumArtUrl;
        if (s.albumArt != null && 
            s.albumArt!.isNotEmpty &&
            !s.albumArt!.contains('placeholder') &&
            !s.albumArt!.contains('picsum.photos') &&
            !s.albumArt!.startsWith('data:')) { // Skip data URIs for Android
          // Support http/https URLs only
          albumArtUrl = s.albumArt!.startsWith('http')
              ? s.albumArt!
              : '${ApiConfig.baseUrl}${s.albumArt}';
        }
        
        audioSources.add(
          AudioSource.uri(
            Uri.parse(audioUrl),
            tag: MediaItem(
              id: s.id,
              title: s.title,
              artist: s.artist,
              album: 'Breaking Hits',
              duration: s.duration,
              artUri: albumArtUrl != null ? Uri.parse(albumArtUrl) : null,
            ),
          ),
        );
      }
      
      final playlist = ConcatenatingAudioSource(children: audioSources);
      
      // Load playlist and seek to start index
      // OPTIMIZATION: Use preload=true for instant playback
      await _audioPlayer.setAudioSource(
        playlist,
        initialIndex: startIndex,
        initialPosition: Duration.zero,
        preload: true, // Preload first song for instant start
      );
      
      // Update Android audio service notification with current song
      if (_audioServiceHandler != null) {
        final currentSong = allSongs[startIndex];
        
        // Get album art URL for the current song (exclude data URIs for Android)
        String? albumArtUrl;
        if (currentSong.albumArt != null && 
            currentSong.albumArt!.isNotEmpty &&
            !currentSong.albumArt!.contains('placeholder') &&
            !currentSong.albumArt!.contains('picsum.photos') &&
            !currentSong.albumArt!.startsWith('data:')) { // Skip data URIs for Android
          // Support http/https URLs only
          albumArtUrl = currentSong.albumArt!.startsWith('http')
              ? currentSong.albumArt!
              : '${ApiConfig.baseUrl}${currentSong.albumArt}';
        }
        
        await _audioServiceHandler!.setQueue(allSongs);
        await _audioServiceHandler!.updateQueueIndex(startIndex);
        await _audioServiceHandler!.setMediaItem(currentSong, artUri: albumArtUrl);
        print('✅ Android notification updated with song metadata');
      }
      
      // Start playing immediately
      print('▶️ Starting queue playback (optimized)...');
      await _audioPlayer.play();
      
      print('✅ Queue loaded, playing from index $startIndex with fast start');
    } catch (e) {
      print('❌ Error playing with queue: $e');
      state = state.copyWith(isLoading: false, isPlaying: false);
    }
  }

  /// Play next song in queue
  Future<void> playNext() async {
    // Use just_audio's built-in next (works for both iOS and Android)
    if (_audioPlayer.hasNext) {
      // Seek to next track - currentIndexStream will auto-sync everything
      // (including resetting tracking flags and starting new session)
      await _audioPlayer.seekToNext();
      
      print('⏭️ Skipped to next track');
    } else {
      print('⏹️ No next song available');
    }
  }

  /// Play previous song
  Future<void> playPrevious() async {
    // Use just_audio's built-in previous (works for both iOS and Android)
    if (_audioPlayer.hasPrevious) {
      // Seek to previous track - currentIndexStream will auto-sync everything
      // (including resetting tracking flags and starting new session)
      await _audioPlayer.seekToPrevious();
      
      print('⏮️ Skipped to previous track');
    } else {
      print('⏹️ No previous song available');
    }
  }

  /// Play/Pause toggle
  Future<void> playPause() async {
    if (_audioPlayer.playing) {
      print('⏸️ Pausing playback...');
      await _audioPlayer.pause();
      // State updated by playerStateStream listener
      print('✅ Playback paused');
    } else {
      print('▶️ Resuming playback...');
      await _audioPlayer.play();
      // State updated by playerStateStream listener
      print('✅ Playback resumed');
    }
  }

  /// Pause playback
  Future<void> pause() async {
    if (_audioPlayer.playing) {
      print('⏸️ Pausing playback...');
      await _audioPlayer.pause();
      // State updated by playerStateStream listener
      print('✅ Playback paused');
    }
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// Skip forward 10 seconds
  Future<void> skipForward() async {
    final newPosition = state.position + const Duration(seconds: 10);
    if (newPosition < state.duration) {
      await seek(newPosition);
    }
  }

  /// Skip backward 10 seconds
  Future<void> skipBackward() async {
    final newPosition = state.position - const Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      await seek(newPosition);
    } else {
      await seek(Duration.zero);
    }
  }

  /// Set playback speed
  Future<void> setSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed);
    state = state.copyWith(speed: speed);
  }

  /// Toggle loop mode
  Future<void> toggleLoopMode() async {
    final newMode = state.loopMode == LoopMode.off
        ? LoopMode.one
        : state.loopMode == LoopMode.one
        ? LoopMode.all
        : LoopMode.off;

    await _audioPlayer.setLoopMode(newMode);
    state = state.copyWith(loopMode: newMode);
  }

  /// Toggle shuffle mode
  Future<void> toggleShuffle() async {
    final newShuffle = !state.shuffleMode;
    await _audioPlayer.setShuffleModeEnabled(newShuffle);
    state = state.copyWith(shuffleMode: newShuffle);
  }

  /// Stop playback
  Future<void> stop() async {
    await _audioPlayer.stop();
    _ref.read(currentSongProvider.notifier).state = null;
  }

  /// Check if user is eligible for token reward (80% completion)
  void _checkTokenEligibility(Duration position) {
    final song = _ref.read(currentSongProvider);
    if (song == null) return;

    final progress = state.duration.inMilliseconds > 0
        ? position.inMilliseconds / state.duration.inMilliseconds
        : 0.0;

    // Update token earn progress
    _ref.read(tokenEarnProvider.notifier).updateProgress(progress);

    // Increment play count at 50% completion (industry standard)
    if (progress >= 0.5 && !_hasIncrementedPlayCount) {
      _incrementPlayCount(song.id);
      _hasIncrementedPlayCount = true;
      print('✅ Play count will be incremented at 50% completion');
    }

    // Reward tokens at 80% completion
    if (progress >= 0.8 && !_hasRewardedCurrentSong) {
      _rewardTokens(song.tokenReward);
      _hasRewardedCurrentSong = true;
    }
  }

  /// Reward tokens to user
  void _rewardTokens(int amount) {
    _ref.read(tokenEarnProvider.notifier).rewardTokens(amount);
    _ref.read(walletProvider.notifier).addTokens(amount);
  }

  /// Increment play count on backend (fire and forget)
  void _incrementPlayCount(String songId) {
    try {
      final songApiService = _ref.read(songApiServiceProvider);
      songApiService.incrementPlayCount(songId).then((playCount) {
        print('✅ Play count incremented: $playCount');
        
        // Update the current song model with new play count
        final currentSong = _ref.read(currentSongProvider);
        if (currentSong != null && currentSong.id == songId) {
          final updatedSong = SongModel(
            id: currentSong.id,
            title: currentSong.title,
            artistId: currentSong.artistId,
            artist: currentSong.artist,
            audioUrl: currentSong.audioUrl,
            duration: currentSong.duration,
            tokenReward: currentSong.tokenReward,
            albumArt: currentSong.albumArt,
            genre: currentSong.genre,
            playCount: playCount, // Update with new count from backend
          );
          _ref.read(currentSongProvider.notifier).state = updatedSong;
          print('✅ Updated current song play count to: $playCount');
        }

        // Update the song in user songs list (real-time update on profile screen)
        _ref.read(userSongsProvider.notifier).updateSongPlayCount(songId, playCount);
        
        // Update the song in discover list (real-time update on discover screen)
        _ref.read(songListProvider.notifier).updateSongPlayCount(songId, playCount);
      }).catchError((error) {
        print('⚠️ Failed to increment play count (non-critical): $error');
      });
    } catch (e) {
      print('⚠️ Error calling increment play count: $e');
    }
  }

  /// Handle song completion
  void _onSongCompleted() async {
    final song = _ref.read(currentSongProvider);
    if (song != null && !_hasRewardedCurrentSong) {
      // Reward if not already done (in case they skipped past 80%)
      _rewardTokens(song.tokenReward);
      _hasRewardedCurrentSong = true;
    }

    // Auto-play next song in queue
    print('🎵 Song completed, checking for next song...');
    final queueNotifier = _ref.read(queueProvider.notifier);
    final nextSong = queueNotifier.playNext();
    
    if (nextSong != null) {
      print('⏭️ Auto-playing next song: ${nextSong.title}');
      await playSong(nextSong);
    } else {
      print('⏹️ Queue ended, stopping playback');
      // Reset to beginning and pause
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.pause();
      
      // Update state to show play button
      state = state.copyWith(
        isPlaying: false,
        position: Duration.zero,
      );
    }
  }

  /// Cleanup method to prevent memory leaks
  void disposePlayer() {
    if (_isDisposed) return;
    _isDisposed = true;
    
    print('🧹 Cleaning up audio player...');
    
    // Cancel all stream subscriptions
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    // Dispose audio service handler
    if (_audioServiceHandler != null) {
      _audioServiceHandler!.dispose();
    }
    
    // Dispose audio player
    _audioPlayer.dispose();
    
    print('✅ Audio player cleaned up');
  }

  @override
  void dispose() {
    disposePlayer();
    super.dispose();
  }
}

class TokenEarnNotifier extends StateNotifier<models.TokenEarnState> {
  TokenEarnNotifier(Ref ref) : super(const models.TokenEarnState());

  void updateProgress(double progress) {
    final isEligible = progress >= 0.8;
    state = state.copyWith(progress: progress, isEligible: isEligible);
  }

  void rewardTokens(int amount) {
    state = state.copyWith(
      tokensEarned: state.tokensEarned + amount,
      hasRewarded: true,
    );
  }

  void reset() {
    state = const models.TokenEarnState();
  }
}
