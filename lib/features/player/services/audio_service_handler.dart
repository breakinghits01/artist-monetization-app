import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/song_model.dart';

/// Callback for skip next from notification/lock screen
typedef SkipCallback = Future<void> Function();

/// Background audio service handler
/// Manages media controls, notifications, and lock screen display
class AudioServiceHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player;
  final List<StreamSubscription> _subscriptions = [];
  SkipCallback? onSkipToNext;
  SkipCallback? onSkipToPrevious;
  
  AudioServiceHandler(this._player) {
    _init();
  }

  void _init() {
    // Listen ONLY to play/pause/buffer state changes (not position)
    _subscriptions.add(
      _player.playerStateStream.listen((playerState) {
        _updatePlaybackState();
      }),
    );

    // Update position periodically (every 1 second) - lightweight, no rebuild
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_subscriptions.isEmpty) { // Check if handler is still active
        _updatePositionOnly();
      } else {
        timer.cancel();
      }
    });

    // Listen to duration changes
    _subscriptions.add(
      _player.durationStream.listen((duration) {
        if (duration != null && mediaItem.value != null) {
          mediaItem.add(mediaItem.value!.copyWith(duration: duration));
        }
      }),
    );
  }

  /// Update full playback state (called when play/pause/skip changes)
  void _updatePlaybackState() {
    final playing = _player.playing;
    
    playbackState.add(playbackState.value.copyWith(
      controls: [
        const MediaControl(
          androidIcon: 'drawable/ic_shuffle',
          label: 'Shuffle',
          action: MediaAction.setShuffleMode,
        ),
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        const MediaControl(
          androidIcon: 'drawable/ic_repeat',
          label: 'Repeat',
          action: MediaAction.setRepeatMode,
        ),
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.setShuffleMode,
        MediaAction.setRepeatMode,
      },
      androidCompactActionIndices: const [1, 2, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: 0,
    ));
  }

  /// Update position only (lightweight, no notification rebuild)
  void _updatePositionOnly() {
    if (_player.processingState != ProcessingState.idle) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
      ));
    }
  }

  /// Update media item for lock screen and notification
  Future<void> setMediaItem(SongModel song, {String? artUri}) async {
    // Don't update if it's the same song (prevents notification rebuild)
    if (mediaItem.value?.id == song.id) {
      print('⏭️ Same song, skipping media item update');
      return;
    }
    
    final item = MediaItem(
      id: song.id,
      album: 'Breaking Hits',
      title: song.title,
      artist: song.artist,
      duration: song.duration,
      artUri: artUri != null ? Uri.parse(artUri) : null,
      // Additional metadata for rich lock screen display
      extras: {
        'tokenReward': song.tokenReward,
        'genre': song.genre ?? 'Unknown',
      },
    );
    
    mediaItem.add(item);
    
    print('🎵 Updated media item: ${song.title} by ${song.artist}');
  }

  @override
  Future<void> play() async {
    print('▶️ Audio Service: Play');
    await _player.play();
  }

  @override
  Future<void> pause() async {
    print('⏸️ Audio Service: Pause');
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    print('⏩ Audio Service: Seek to $position');
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    print('⏭️ Audio Service: Skip to next');
    if (onSkipToNext != null) {
      await onSkipToNext!();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    print('⏮️ Audio Service: Skip to previous');
    if (onSkipToPrevious != null) {
      await onSkipToPrevious!();
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    print('🔁 Audio Service: Set repeat mode to $repeatMode');
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
        await _player.setLoopMode(LoopMode.all);
        break;
      default:
        await _player.setLoopMode(LoopMode.off);
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    print('🔀 Audio Service: Set shuffle mode to $shuffleMode');
    final enabled = shuffleMode == AudioServiceShuffleMode.all;
    await _player.setShuffleModeEnabled(enabled);
  }

  @override
  Future<void> stop() async {
    print('⏹️ Audio Service: Stop');
    await _player.stop();
    await super.stop();
  }

  /// Clean up resources
  /// Note: Does NOT dispose the shared AudioPlayer instance
  /// Only cancels this handler's stream subscriptions
  Future<void> dispose() async {
    print('🧹 Cleaning up AudioServiceHandler...');
    
    // Cancel all stream subscriptions
    for (var subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    
    // Stop the audio service
    await stop();
    
    print('✅ AudioServiceHandler cleaned up');
  }
}

/// Initialize audio service
/// Call this once at app startup
Future<AudioServiceHandler> initAudioService(AudioPlayer player) async {
  print('🎵 Initializing audio service...');
  
  // Configure audio session for background playback
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration(
    avAudioSessionCategory: AVAudioSessionCategory.playback,
    avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
    avAudioSessionMode: AVAudioSessionMode.defaultMode, // Use default mode for music (was spokenAudio)
    avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
    avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
    androidAudioAttributes: AndroidAudioAttributes(
      contentType: AndroidAudioContentType.music,
      flags: AndroidAudioFlags.none,
      usage: AndroidAudioUsage.media,
    ),
    androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
    androidWillPauseWhenDucked: false,
  ));
  
  print('✅ Audio session configured');
  
  final handler = await AudioService.init(
    builder: () => AudioServiceHandler(player),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.breakinghits.monetization.audio',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationChannelDescription: 'Playing music from Breaking Hits',
      androidNotificationOngoing: false, // Notification can be dismissed
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidShowNotificationBadge: true,
      androidStopForegroundOnPause: false, // Keep notification persistent - prevents bounce
      preloadArtwork: true, // Preload artwork for instant display
      artDownscaleWidth: 200,
      artDownscaleHeight: 200,
      fastForwardInterval: Duration(seconds: 10),
      rewindInterval: Duration(seconds: 10),
    ),
  );
  
  print('✅ Audio service initialized');
  return handler;
}
