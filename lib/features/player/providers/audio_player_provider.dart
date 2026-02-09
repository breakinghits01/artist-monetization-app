import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';
import '../models/player_state.dart' as models;
import '../../home/providers/wallet_provider.dart';

/// Current song provider
final currentSongProvider = StateProvider<SongModel?>((ref) => null);

/// Player expanded state
final playerExpandedProvider = StateProvider<bool>((ref) => false);

/// Audio player provider
final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerNotifier, models.PlayerState>(
      (ref) => AudioPlayerNotifier(ref),
    );

/// Token earn state provider
final tokenEarnProvider =
    StateNotifierProvider<TokenEarnNotifier, models.TokenEarnState>(
      (ref) => TokenEarnNotifier(ref),
    );

class AudioPlayerNotifier extends StateNotifier<models.PlayerState> {
  final Ref _ref;
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _bufferingSubscription;

  bool _hasRewardedCurrentSong = false;

  AudioPlayerNotifier(this._ref) : super(const models.PlayerState()) {
    _initPlayer();
  }

  void _initPlayer() {
    // Listen to position changes
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      state = state.copyWith(position: position);
      _checkTokenEligibility(position);
    });

    // Listen to duration changes
    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(duration: duration);
      }
    });

    // Listen to player state changes
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((
      playerState,
    ) {
      state = state.copyWith(
        isPlaying: playerState.playing,
        isLoading: playerState.processingState == ProcessingState.loading,
      );

      // Auto-play next song when current ends
      if (playerState.processingState == ProcessingState.completed) {
        _onSongCompleted();
      }
    });

    // Listen to buffering state
    _bufferingSubscription = _audioPlayer.bufferedPositionStream.listen((
      buffered,
    ) {
      final isBuffering =
          buffered < state.position &&
          _audioPlayer.processingState == ProcessingState.buffering;
      state = state.copyWith(isBuffering: isBuffering);
    });
  }

  /// Play a song
  Future<void> playSong(SongModel song) async {
    try {
      state = state.copyWith(isLoading: true);
      _ref.read(currentSongProvider.notifier).state = song;
      _hasRewardedCurrentSong = false;

      // Reset token earn state
      _ref.read(tokenEarnProvider.notifier).reset();

      await _audioPlayer.setUrl(song.audioUrl);
      await _audioPlayer.play();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      print('Error playing song: $e');
      // TODO: Show error to user
    }
  }

  /// Play/Pause toggle
  Future<void> playPause() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  /// Pause playback
  Future<void> pause() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
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
  void _onSongCompleted() {
    final song = _ref.read(currentSongProvider);
    if (song != null && !_hasRewardedCurrentSong) {
      // Reward if not already done (in case they skipped past 80%)
      _rewardTokens(song.tokenReward);
      _hasRewardedCurrentSong = true;
    }

    // TODO: Play next song in queue
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _bufferingSubscription?.cancel();
    _audioPlayer.dispose();
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
