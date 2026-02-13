# Stability & Background Playback Implementation Plan

**Date**: February 13, 2026  
**Priority**: CRITICAL  
**Goal**: Fix memory leaks, ensure app stability, and implement proper background audio playback for iOS and Android

---

## 🔍 Current Issues Identified

### 1. **Memory Leaks** ⚠️
```dart
// ISSUE: AudioPlayer instance in provider never properly disposed
class AudioPlayerNotifier extends StateNotifier<models.PlayerState> {
  final AudioPlayer _audioPlayer = AudioPlayer(); // ❌ Created but may leak
  
  @override
  void dispose() {
    // ✅ Dispose is called, but need to verify
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _bufferingSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
```

**Problems:**
- Provider may not dispose properly if app is killed
- Stream subscriptions might not be cancelled in all scenarios
- Multiple AudioPlayer instances could be created

### 2. **Background Playback Issues** ❌
```dart
// ISSUE: Music stops when screen turns off
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  // ❌ THIS PAUSES MUSIC WHEN APP GOES TO BACKGROUND!
  if (state == AppLifecycleState.paused) {
    ref.read(audioPlayerProvider.notifier).pause(); // BAD!
  }
}
```

**Problems:**
- Music pauses when screen locks
- No background audio service configured
- Missing platform-specific permissions
- No audio focus handling
- No notification controls (play/pause/skip)

### 3. **Queue Management Missing** ❌
```dart
// ISSUE: No playlist queue system
// When playing a song, the next songs in the list don't auto-play
void _onSongCompleted() async {
  // Reset to beginning and pause
  await _audioPlayer.seek(Duration.zero);
  await _audioPlayer.pause();
  
  // TODO: Play next song in queue  ❌ NOT IMPLEMENTED!
}
```

**Problems:**
- Playing a song doesn't add the rest of the list to queue
- Song completes and stops (doesn't auto-play next)
- No concept of "current playlist" or "song queue"
- Recent songs not managed as a playlist
- Can't shuffle or repeat playlist

### 4. **Previous/Next Buttons Not Working** ❌
```dart
// ISSUE: No queue means no previous/next functionality
// Player UI has previous/next buttons but they do nothing
skipForward() // ✅ Works (skips 10 seconds)
skipBackward() // ✅ Works (skips 10 seconds back)

// ❌ These don't exist:
playNext() // Should play next song in queue
playPrevious() // Should play previous song in queue
```

**Problems:**
- Previous button doesn't work (no previous song tracking)
- Next button doesn't work (no queue management)
- No song history
- Can't navigate between songs in a playlist/album

### 5. **Missing Configurations**

#### Android Issues:
- ❌ No WAKE_LOCK permission
- ❌ No FOREGROUND_SERVICE permission  
- ❌ No audio service declaration
- ❌ No notification channel for media controls

#### iOS Issues:
- ❌ No UIBackgroundModes for audio
- ❌ No AVAudioSession configuration
- ❌ No Control Center integration
- ❌ No lock screen controls

---

## 🎯 Solution Architecture

### Architecture Overview
```
┌─────────────────────────────────────────────────────┐
│                   Flutter App Layer                  │
│  ┌──────────────────────────────────────────────┐   │
│  │     Audio Player Provider (UI State)          │   │
│  │     - Play/Pause/Seek controls               │   │
│  │     - Progress tracking                       │   │
│  │     - Token rewards                          │   │
│  └──────────────────────────────────────────────┘   │
│                        ↕                             │
│  ┌──────────────────────────────────────────────┐   │
│  │       Audio Service Handler                   │   │
│  │     - Background playback                     │   │
│  │     - Audio focus management                  │   │
│  │     - Notification controls                   │   │
│  └──────────────────────────────────────────────┘   │
│                        ↕                             │
│  ┌──────────────────────────────────────────────┐   │
│  │          just_audio Player                    │   │
│  │     - Audio decoding                         │   │
│  │     - Stream management                       │   │
│  │     - Playback engine                        │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
                        ↕
┌─────────────────────────────────────────────────────┐
│              Platform Audio Services                 │
│  ┌──────────────┐           ┌──────────────┐       │
│  │   Android    │           │      iOS     │       │
│  │              │           │              │       │
│  │ MediaSession │           │ AVAudioSession│      │
│  │ MediaStyle   │           │ NowPlaying   │       │
│  │ Notification │           │ RemoteCommand│       │
│  └──────────────┘           └──────────────┘       │
└─────────────────────────────────────────────────────┘
```

---

## 📋 Implementation Checklist

### Phase 1: Fix Memory Leaks (Day 1) ✅

#### 1.1 Provider Lifecycle Management
```dart
// BEFORE: Potential memory leak
final audioPlayerProvider = StateNotifierProvider<AudioPlayerNotifier, PlayerState>((ref) {
  return AudioPlayerNotifier(ref); // May not dispose
});

// AFTER: Proper disposal
final audioPlayerProvider = StateNotifierProvider.autoDispose<AudioPlayerNotifier, PlayerState>((ref) {
  final notifier = AudioPlayerNotifier(ref);
  
  // Ensure cleanup when provider is disposed
  ref.onDispose(() {
    notifier.disposePlayer();
  });
  
  return notifier;
});
```

#### 1.2 Stream Management
```dart
// Add proper cleanup method
class AudioPlayerNotifier extends StateNotifier<PlayerState> {
  Timer? _progressTimer;
  List<StreamSubscription> _subscriptions = [];
  
  void _initPlayer() {
    // Store all subscriptions for cleanup
    _subscriptions.add(_audioPlayer.positionStream.listen(...));
    _subscriptions.add(_audioPlayer.durationStream.listen(...));
    _subscriptions.add(_audioPlayer.playerStateStream.listen(...));
  }
  
  void disposePlayer() {
    // Cancel all subscriptions
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    
    // Cancel timers
    _progressTimer?.cancel();
    
    // Dispose audio player
    _audioPlayer.dispose();
  }
}
```

#### 1.3 Widget Cleanup
```dart
// Ensure widgets properly dispose
class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  ScrollController? _scrollController;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }
  
  @override
  void dispose() {
    _scrollController?.dispose();
    // Animation controllers should also be disposed
    super.dispose();
  }
}
```

---

### Phase 2: Background Audio Setup (Day 2-3) 🎵

#### 2.1 Install Required Packages
```yaml
# pubspec.yaml
dependencies:
  audio_service: ^0.18.12         # ✅ Already installed
  audio_session: ^0.1.19          # ✅ Already installed
  just_audio: ^0.9.36             # ✅ Already installed
  just_audio_background: ^0.0.1-beta.11  # ❌ ADD THIS
```

#### 2.2 Android Configuration

**AndroidManifest.xml** additions:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- ADD THESE PERMISSIONS -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
    
    <application>
        <!-- ADD AUDIO SERVICE -->
        <service 
            android:name="com.ryanheise.audioservice.AudioService"
            android:foregroundServiceType="mediaPlayback"
            android:exported="true">
            <intent-filter>
                <action android:name="android.media.browse.MediaBrowserService" />
            </intent-filter>
        </service>
        
        <!-- NOTIFICATION RECEIVER -->
        <receiver 
            android:name="com.ryanheise.audioservice.MediaButtonReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MEDIA_BUTTON" />
            </intent-filter>
        </receiver>
    </application>
</manifest>
```

#### 2.3 iOS Configuration

**Info.plist** additions:
```xml
<dict>
    <!-- ADD BACKGROUND AUDIO MODE -->
    <key>UIBackgroundModes</key>
    <array>
        <string>audio</string>
    </array>
    
    <!-- AUDIO SESSION CATEGORY -->
    <key>UIRequiresPersistentWiFi</key>
    <false/>
    
    <!-- NOTIFICATION PERMISSIONS -->
    <key>NSUserNotificationUsageDescription</key>
    <string>We need notification permission to show playback controls</string>
</dict>
```

**Podfile** additions:
```ruby
# ios/Podfile
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # ADD THIS FOR BACKGROUND AUDIO
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'AUDIO_SERVICE_BACKGROUND_AUDIO=1'
      ]
    end
  end
end
```

---

### Phase 3: Queue Management System (Day 4-5) 🎵

#### 3.1 Create Queue Provider
```dart
// lib/features/player/providers/queue_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song_model.dart';

/// Song queue state
class QueueState {
  final List<SongModel> queue;
  final int currentIndex;
  final List<SongModel> history;
  final bool shuffle;
  final LoopMode loopMode;
  
  const QueueState({
    this.queue = const [],
    this.currentIndex = -1,
    this.history = const [],
    this.shuffle = false,
    this.loopMode = LoopMode.off,
  });
  
  QueueState copyWith({
    List<SongModel>? queue,
    int? currentIndex,
    List<SongModel>? history,
    bool? shuffle,
    LoopMode? loopMode,
  }) {
    return QueueState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      history: history ?? this.history,
      shuffle: shuffle ?? this.shuffle,
      loopMode: loopMode ?? this.loopMode,
    );
  }
  
  bool get hasNext => currentIndex < queue.length - 1;
  bool get hasPrevious => history.isNotEmpty || currentIndex > 0;
  SongModel? get currentSong => 
      currentIndex >= 0 && currentIndex < queue.length 
          ? queue[currentIndex] 
          : null;
  SongModel? get nextSong => 
      hasNext ? queue[currentIndex + 1] : null;
}

final queueProvider = StateNotifierProvider<QueueNotifier, QueueState>(
  (ref) => QueueNotifier(),
);

class QueueNotifier extends StateNotifier<QueueState> {
  QueueNotifier() : super(const QueueState());
  
  /// Set new queue and start playing from index
  void setQueue(List<SongModel> songs, {int startIndex = 0}) {
    state = state.copyWith(
      queue: songs,
      currentIndex: startIndex,
      history: [],
    );
  }
  
  /// Add song to queue
  void addToQueue(SongModel song) {
    final newQueue = [...state.queue, song];
    state = state.copyWith(queue: newQueue);
  }
  
  /// Play next song in queue
  SongModel? playNext() {
    if (!state.hasNext) {
      // Handle loop mode
      if (state.loopMode == LoopMode.all && state.queue.isNotEmpty) {
        // Loop to beginning
        final newHistory = [...state.history, state.currentSong!];
        state = state.copyWith(
          currentIndex: 0,
          history: newHistory,
        );
        return state.currentSong;
      }
      return null; // No next song
    }
    
    // Add current to history
    if (state.currentSong != null) {
      final newHistory = [...state.history, state.currentSong!];
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        history: newHistory,
      );
    } else {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
    
    return state.currentSong;
  }
  
  /// Play previous song
  SongModel? playPrevious() {
    if (!state.hasPrevious) return null;
    
    // Get from history if available
    if (state.history.isNotEmpty) {
      final previousSong = state.history.last;
      final newHistory = state.history.sublist(0, state.history.length - 1);
      
      // Find song in queue
      final index = state.queue.indexWhere((s) => s.id == previousSong.id);
      if (index >= 0) {
        state = state.copyWith(
          currentIndex: index,
          history: newHistory,
        );
        return state.currentSong;
      }
    }
    
    // Or go to previous index
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
      return state.currentSong;
    }
    
    return null;
  }
  
  /// Toggle shuffle
  void toggleShuffle() {
    state = state.copyWith(shuffle: !state.shuffle);
    if (state.shuffle) {
      _shuffleQueue();
    } else {
      // TODO: Restore original order
    }
  }
  
  /// Toggle loop mode
  void toggleLoop() {
    final nextMode = state.loopMode == LoopMode.off
        ? LoopMode.one
        : state.loopMode == LoopMode.one
        ? LoopMode.all
        : LoopMode.off;
    state = state.copyWith(loopMode: nextMode);
  }
  
  void _shuffleQueue() {
    if (state.queue.isEmpty) return;
    
    final currentSong = state.currentSong;
    final remainingSongs = [...state.queue];
    
    if (currentSong != null) {
      remainingSongs.removeWhere((s) => s.id == currentSong.id);
    }
    
    remainingSongs.shuffle();
    
    final newQueue = currentSong != null 
        ? [currentSong, ...remainingSongs]
        : remainingSongs;
    
    state = state.copyWith(
      queue: newQueue,
      currentIndex: 0,
    );
  }
  
  /// Clear queue
  void clear() {
    state = const QueueState();
  }
}
```

#### 3.2 Update Audio Player Provider with Queue
```dart
// Update audio_player_provider.dart

class AudioPlayerNotifier extends StateNotifier<models.PlayerState> {
  final Ref _ref;
  
  /// Play a song and set queue from list
  Future<void> playSongWithQueue(
    SongModel song, 
    List<SongModel> allSongs,
  ) async {
    try {
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
      print('Error playing with queue: $e');
    }
  }
  
  /// Play next song in queue
  Future<void> playNext() async {
    final nextSong = _ref.read(queueProvider.notifier).playNext();
    if (nextSong != null) {
      await playSong(nextSong);
    }
  }
  
  /// Play previous song
  Future<void> playPrevious() async {
    final previousSong = _ref.read(queueProvider.notifier).playPrevious();
    if (previousSong != null) {
      await playSong(previousSong);
    }
  }
  
  /// Handle song completion - auto-play next
  void _onSongCompleted() async {
    final song = _ref.read(currentSongProvider);
    if (song != null && !_hasRewardedCurrentSong) {
      _rewardTokens(song.tokenReward);
      _hasRewardedCurrentSong = true;
    }
    
    // Auto-play next song in queue
    final queueState = _ref.read(queueProvider);
    
    // Check loop mode
    if (queueState.loopMode == LoopMode.one) {
      // Repeat current song
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
      return;
    }
    
    // Play next song
    final hasNext = queueState.hasNext || queueState.loopMode == LoopMode.all;
    if (hasNext) {
      await playNext();
    } else {
      // No more songs - stop at end
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.pause();
      state = state.copyWith(isPlaying: false, position: Duration.zero);
    }
  }
}
```

#### 3.3 Update UI to Use Queue
```dart
// In profile_screen.dart, discover_screen.dart, etc.

// BEFORE: Just play single song
void _handleSongPlay(SongModel song) {
  ref.read(audioPlayerProvider.notifier).playSong(song);
}

// AFTER: Play with queue context
void _handleSongPlay(SongModel song) {
  final allSongs = _getSortedSongs(); // or current list
  ref.read(audioPlayerProvider.notifier).playSongWithQueue(
    song,
    allSongs,
  );
}
```

---

### Phase 4: Audio Service Handler (Day 6-7) 🔧

#### 4.1 Create Audio Handler
```dart
// lib/features/player/services/audio_handler.dart

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MusicAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  
  MusicAudioHandler() {
    // Initialize player
    _init();
  }
  
  Future<void> _init() async {
    // Configure audio session
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    
    // Listen to player events
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    
    // Handle audio interruptions (phone calls, etc.)
    session.interruptionEventStream.listen(_handleInterruption);
    
    // Handle becoming noisy (headphones unplugged)
    session.becomingNoisyEventStream.listen((_) {
      pause();
    });
  }
  
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: 0,
    );
  }
  
  @override
  Future<void> play() => _player.play();
  
  @override
  Future<void> pause() => _player.pause();
  
  @override
  Future<void> stop() => _player.stop();
  
  @override
  Future<void> seek(Duration position) => _player.seek(position);
  
  @override
  Future<void> skipToNext() => _player.seekToNext();
  
  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();
  
  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);
  
  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    this.mediaItem.add(mediaItem);
    await _player.setUrl(mediaItem.extras!['url'] as String);
    await play();
  }
  
  void _handleInterruption(AudioInterruptionEvent event) {
    if (event.begin) {
      // Pause on interruption (phone call)
      if (_player.playing) pause();
    } else {
      // Resume after interruption if needed
      switch (event.type) {
        case AudioInterruptionType.duck:
          // Lower volume
          _player.setVolume(0.5);
          break;
        case AudioInterruptionType.pause:
        case AudioInterruptionType.unknown:
          // Stay paused
          break;
      }
    }
  }
  
  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    // Handle custom actions (like, unlike, add to playlist, etc.)
    switch (name) {
      case 'setUrl':
        await _player.setUrl(extras!['url'] as String);
        break;
    }
  }
}
```

#### 3.2 Initialize Audio Service
```dart
// lib/main.dart

import 'package:audio_service/audio_service.dart';
import 'features/player/services/audio_handler.dart';

late AudioHandler audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize audio service
  audioHandler = await AudioService.init(
    builder: () => MusicAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.breakinghits.app.channel.audio',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidShowNotificationBadge: true,
    ),
  );
  
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}
```

#### 3.3 Update Audio Player Provider
```dart
// lib/features/player/providers/audio_player_provider.dart

class AudioPlayerNotifier extends StateNotifier<models.PlayerState> {
  final Ref _ref;
  final AudioHandler _audioHandler;
  StreamSubscription? _playbackSubscription;
  
  AudioPlayerNotifier(this._ref, this._audioHandler) : super(const models.PlayerState()) {
    _initPlayer();
  }
  
  void _initPlayer() {
    // Listen to playback state from audio handler
    _playbackSubscription = _audioHandler.playbackState.listen((state) {
      this.state = this.state.copyWith(
        isPlaying: state.playing,
        position: state.position,
        bufferedPosition: state.bufferedPosition,
        isLoading: state.processingState == AudioProcessingState.loading,
      );
    });
    
    // Listen to media item changes
    _audioHandler.mediaItem.listen((item) {
      if (item != null) {
        // Update current song from media item
        _ref.read(currentSongProvider.notifier).state = _songFromMediaItem(item);
      }
    });
  }
  
  Future<void> playSong(SongModel song) async {
    try {
      state = state.copyWith(isLoading: true);
      
      // Create media item for notification
      final mediaItem = MediaItem(
        id: song.id,
        title: song.title,
        artist: song.artist,
        artUri: song.albumArt != null ? Uri.parse(song.albumArt!) : null,
        duration: song.duration,
        extras: {
          'url': song.audioUrl,
        },
      );
      
      // Play through audio handler (background-capable)
      await _audioHandler.playMediaItem(mediaItem);
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      print('Error: $e');
    }
  }
  
  Future<void> playPause() async {
    if (state.isPlaying) {
      await _audioHandler.pause();
    } else {
      await _audioHandler.play();
    }
  }
  
  @override
  void dispose() {
    _playbackSubscription?.cancel();
    super.dispose();
  }
}
```

---

### Phase 5: Remove Lifecycle Pause (Day 8) 🔧

```dart
// lib/main.dart

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // ❌ REMOVE THIS - Let audio service handle it!
    // if (state == AppLifecycleState.paused) {
    //   ref.read(audioPlayerProvider.notifier).pause();
    // }
    
    // ✅ NEW: Only handle app-specific logic
    if (state == AppLifecycleState.resumed) {
      // Sync UI state with audio service when app resumes
      _syncPlayerState();
    }
  }
  
  void _syncPlayerState() {
    // Get current state from audio handler and update UI
    final playbackState = audioHandler.playbackState.valueOrNull;
    if (playbackState != null) {
      // UI will automatically update through provider listeners
    }
  }
}
```

---

### Phase 6: Notification Controls (Day 9) 📱

#### 5.1 Media Notification
The `audio_service` package automatically creates:
- ✅ Android: MediaStyle notification with play/pause/skip
- ✅ iOS: Lock screen controls + Control Center
- ✅ Bluetooth/Headphone controls
- ✅ Auto-pause on interruption (phone calls)
- ✅ Auto-pause when headphones unplug

#### 5.2 Custom Actions
```dart
// Add custom actions to notification
class MusicAudioHandler extends BaseAudioHandler {
  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'like':
        // Handle like action
        break;
      case 'addToPlaylist':
        // Handle add to playlist
        break;
    }
  }
}

// Update controls with custom actions
PlaybackState(
  controls: [
    MediaControl.skipToPrevious,
    if (_player.playing) MediaControl.pause else MediaControl.play,
    MediaControl.skipToNext,
    const MediaControl(
      androidIcon: 'drawable/ic_favorite',
      label: 'Like',
      action: MediaAction.custom,
      customAction: CustomMediaAction('like'),
    ),
  ],
  // ...
);
```

---

### Phase 7: Testing & Optimization (Day 10-11) 🧪

#### 6.1 Memory Leak Testing
```bash
# Run Flutter DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Check for memory leaks
# 1. Open DevTools Memory tab
# 2. Play several songs
# 3. Pause and resume app
# 4. Lock/unlock screen
# 5. Take heap snapshot
# 6. Look for retained AudioPlayer instances
```

#### 6.2 Background Playback Testing

**Android Testing:**
- [ ] Music continues when screen locks
- [ ] Music continues when app minimized
- [ ] Notification controls work
- [ ] Bluetooth controls work
- [ ] Headphone unplug pauses music
- [ ] Phone call pauses music
- [ ] Music resumes after call (if playing before)

**iOS Testing:**
- [ ] Music continues when screen locks
- [ ] Music continues when app minimized
- [ ] Control Center shows controls
- [ ] Lock screen shows controls
- [ ] AirPods controls work
- [ ] Bluetooth controls work
- [ ] Phone call interruption handling
- [ ] Siri integration (optional)

#### 6.3 Performance Testing
```dart
// Add performance monitoring
import 'package:flutter/foundation.dart';

class PerformanceMonitor {
  static final Stopwatch _playbackTimer = Stopwatch();
  
  static void trackPlayback(String event) {
    if (kDebugMode) {
      print('🎵 Playback Event: $event at ${_playbackTimer.elapsedMilliseconds}ms');
    }
  }
  
  static void startTracking() => _playbackTimer.start();
  static void resetTracking() => _playbackTimer.reset();
}
```

---

## 🎯 Success Criteria

### Memory Management ✅
- [ ] No memory leaks in DevTools profiler
- [ ] AudioPlayer properly disposed
- [ ] Stream subscriptions cancelled
- [ ] Widget controllers disposed
- [ ] Provider properly auto-disposed

### Background Playback ✅
- [ ] Music plays with screen off (Android & iOS)
- [ ] Music plays when app minimized
- [ ] Notification controls functional
- [ ] Lock screen controls functional
- [ ] Bluetooth/headphone controls work
- [ ] Proper interruption handling

### Queue Management ✅
- [ ] Playing a song auto-queues remaining songs in list
- [ ] Song auto-plays next when current completes
- [ ] Previous button works (plays previous song)
- [ ] Next button works (plays next song)
- [ ] Queue visible in player UI
- [ ] Shuffle mode works
- [ ] Loop modes work (off/one/all)
- [ ] Recent songs create playable queue

### Stability ✅
- [ ] No crashes on lock/unlock
- [ ] No crashes on app minimize/restore
- [ ] Smooth playback transitions
- [ ] Proper error handling
- [ ] Network interruption handling

---

## 📊 Implementation Timeline

| Phase | Task | Duration | Dependencies |
|-------|------|----------|--------------|
| 1 | Fix Memory Leaks | 1 day | None |
| 2 | Platform Configuration | 1 day | Phase 1 |
| 3 | Queue Management System | 2 days | Phase 1 |
| 4 | Audio Service Handler | 2 days | Phase 2, 3 |
| 5 | Remove Lifecycle Pause | 0.5 day | Phase 4 |
| 6 | Notification Controls | 1 day | Phase 4 |
| 7 | Testing & Optimization | 2 days | All phases |
| **Total** | **Complete Implementation** | **9.5 days** | |

---

## 🔐 Security Considerations

1. **Audio URLs**: Ensure streaming URLs are secure (HTTPS)
2. **Token Verification**: Validate token rewards server-side
3. **Background Limits**: Respect OS battery optimization
4. **User Privacy**: Handle audio focus properly (pause for calls)

---

## 📝 Migration Notes

### Breaking Changes
- `AudioPlayerNotifier` constructor will require `AudioHandler`
- Lifecycle pause logic removed from `main.dart`
- Provider will be auto-dispose

### Backward Compatibility
- Existing song playback will work seamlessly
- Token reward system unchanged
- UI components unchanged

---

## 🚀 Quick Start Commands

```bash
# 1. Add dependencies
flutter pub add just_audio_background

# 2. Update Android minSdkVersion
# android/app/build.gradle -> minSdkVersion 21

# 3. Run pod install (iOS)
cd ios && pod install && cd ..

# 4. Test background playback
flutter run

# 5. Test on real device (required for accurate testing)
flutter run --release
```

---

## 📚 Reference Documentation

- [audio_service package](https://pub.dev/packages/audio_service)
- [just_audio background](https://pub.dev/packages/just_audio_background)
- [Android MediaSession](https://developer.android.com/guide/topics/media-apps/working-with-a-media-session)
- [iOS Background Audio](https://developer.apple.com/documentation/avfoundation/media_playback/creating_a_basic_video_player_ios_and_tvos/enabling_background_audio)

---

**Ready to implement?** Start with Phase 1 (Fix Memory Leaks) and proceed sequentially. Each phase builds on the previous one. 🎵
