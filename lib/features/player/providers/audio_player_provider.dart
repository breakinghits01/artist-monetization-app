import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';
import '../models/player_state.dart' as models;
import '../../home/providers/wallet_provider.dart';
import '../../../core/config/api_config.dart';
import 'queue_provider.dart';
import '../services/audio_service_handler.dart';

/// Current song provider
final currentSongProvider = StateProvider<SongModel?>((ref) => null);

/// Player expanded state
final playerExpandedProvider = StateProvider<bool>((ref) => false);

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
  bool _isDisposed = false;

  AudioPlayerNotifier(this._ref) : super(const models.PlayerState()) {
    _initPlayer();
    _initAudioService();
  }

  /// Initialize audio service for background playback
  Future<void> _initAudioService() async {
    try {
      _audioServiceHandler = await initAudioService(_audioPlayer);
      
      // Connect skip callbacks to queue methods
      _audioServiceHandler!.onSkipToNext = () => playNext();
      _audioServiceHandler!.onSkipToPrevious = () => playPrevious();
      
      print('✅ Audio service ready for background playback');
    } catch (e) {
      print('⚠️ Failed to initialize audio service: $e');
      // Continue without background service if initialization fails
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

      // Reset token earn state
      _ref.read(tokenEarnProvider.notifier).reset();

      // Stop current playback first
      await _audioPlayer.stop();
      
      print('🔗 Loading audio URL...');
      
      // Convert relative URLs to absolute ngrok URLs
      String audioUrl = song.audioUrl;
      if (!audioUrl.startsWith('http')) {
        // Relative URL - prepend base URL
        audioUrl = '${ApiConfig.baseUrl}$audioUrl';
        print('🔗 Converted to absolute URL: $audioUrl');
      } else {
        print('🔗 Using provided absolute URL: $audioUrl');
      }
      
      print('🔗 Final URL: $audioUrl');
      print('🔗 Base URL from config: ${ApiConfig.baseUrl}');
      
      // Add timeout to prevent hanging (increased to 30 seconds)
      await _audioPlayer.setUrl(audioUrl).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Audio loading timeout after 30s - URL: $audioUrl');
        },
      );
      
      print('▶️ Playing audio...');
      await _audioPlayer.play();

      // Update media item for lock screen and notification
      if (_audioServiceHandler != null) {
        // Filter out placeholder URLs from database
        String? albumArtUrl;
        if (song.albumArt != null && 
            !song.albumArt!.contains('placeholder') &&
            !song.albumArt!.contains('picsum.photos')) {
          albumArtUrl = song.albumArt!.startsWith('http')
              ? song.albumArt
              : '${ApiConfig.baseUrl}${song.albumArt}';
        }
        
        await _audioServiceHandler!.setMediaItem(song, artUri: albumArtUrl);
        print('🎨 Updated lock screen media item');
      }

      // Clear loading state - playing state updated by playerStateStream listener
      state = state.copyWith(
        isLoading: false,
      );
      
      print('✅ Playback started successfully');
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
      
      // Find song index in list
      final songIndex = allSongs.indexWhere((s) => s.id == song.id);
      
      // Set queue starting from this song
      _ref.read(queueProvider.notifier).setQueue(
        allSongs,
        startIndex: songIndex >= 0 ? songIndex : 0,
      );
      
      // Play the song
      await playSong(song);
    } catch (e) {
      print('❌ Error playing with queue: $e');
      state = state.copyWith(isLoading: false, isPlaying: false);
    }
  }

  /// Play next song in queue
  Future<void> playNext() async {
    final nextSong = _ref.read(queueProvider.notifier).playNext();
    if (nextSong != null) {
      await playSong(nextSong);
    } else {
      print('⏹️ No next song available');
    }
  }

  /// Play previous song
  Future<void> playPrevious() async {
    final previousSong = _ref.read(queueProvider.notifier).playPrevious();
    if (previousSong != null) {
      await playSong(previousSong);
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
    if (song == null || _hasRewardedCurrentSong) return;

    final progress = state.duration.inMilliseconds > 0
        ? position.inMilliseconds / state.duration.inMilliseconds
        : 0.0;

    // Update token earn progress
    _ref.read(tokenEarnProvider.notifier).updateProgress(progress);

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
      print('🧹 Audio service handler disposed');
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
