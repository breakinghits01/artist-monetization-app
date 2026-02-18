import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
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
  
  /// Check if there's a next song
  bool get hasNext => currentIndex < queue.length - 1;
  
  /// Check if there's a previous song
  bool get hasPrevious => history.isNotEmpty || currentIndex > 0;
  
  /// Get current song
  SongModel? get currentSong => 
      currentIndex >= 0 && currentIndex < queue.length 
          ? queue[currentIndex] 
          : null;
  
  /// Get next song (without moving index)
  SongModel? get nextSong => 
      hasNext ? queue[currentIndex + 1] : null;
  
  /// Get queue size
  int get queueSize => queue.length;
  
  /// Get remaining songs count
  int get remainingSongs => queue.length - currentIndex - 1;
}

/// Queue provider for managing playback queue
final queueProvider = StateNotifierProvider<QueueNotifier, QueueState>(
  (ref) => QueueNotifier(),
);

class QueueNotifier extends StateNotifier<QueueState> {
  QueueNotifier() : super(const QueueState());
  
  /// Set new queue and start playing from specified index
  void setQueue(List<SongModel> songs, {int startIndex = 0}) {
    if (songs.isEmpty) {
      state = const QueueState();
      return;
    }
    
    // Ensure start index is valid
    final validIndex = startIndex.clamp(0, songs.length - 1);
    
    state = state.copyWith(
      queue: songs,
      currentIndex: validIndex,
      history: [],
    );
    
    print('📋 Queue set: ${songs.length} songs, starting at index $validIndex');
  }
  
  /// Update current index (for syncing with lockscreen changes)
  void setCurrentIndex(int index) {
    if (index >= 0 && index < state.queue.length) {
      state = state.copyWith(currentIndex: index);
      print('📍 Current index updated to: $index');
    }
  }
  
  /// Add single song to end of queue
  void addToQueue(SongModel song) {
    final newQueue = [...state.queue, song];
    state = state.copyWith(queue: newQueue);
    print('➕ Added to queue: ${song.title} (${newQueue.length} total)');
  }
  
  /// Add multiple songs to queue
  void addMultipleToQueue(List<SongModel> songs) {
    final newQueue = [...state.queue, ...songs];
    state = state.copyWith(queue: newQueue);
    print('➕ Added ${songs.length} songs to queue (${newQueue.length} total)');
  }
  
  /// Play next song in queue
  SongModel? playNext() {
    if (!state.hasNext) {
      // Handle loop mode
      if (state.loopMode == LoopMode.all && state.queue.isNotEmpty) {
        // Loop back to beginning
        final newHistory = state.currentSong != null 
            ? [...state.history, state.currentSong!]
            : state.history;
        
        state = state.copyWith(
          currentIndex: 0,
          history: newHistory,
        );
        
        print('🔁 Looping back to start of queue');
        return state.currentSong;
      }
      
      print('⏹️ No next song in queue');
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
    
    print('⏭️ Playing next: ${state.currentSong?.title} (${state.currentIndex + 1}/${state.queue.length})');
    return state.currentSong;
  }
  
  /// Play previous song
  SongModel? playPrevious() {
    if (!state.hasPrevious) {
      print('⏹️ No previous song');
      return null;
    }
    
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
        
        print('⏮️ Playing previous from history: ${state.currentSong?.title}');
        return state.currentSong;
      }
    }
    
    // Or go to previous index
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
      print('⏮️ Playing previous: ${state.currentSong?.title} (${state.currentIndex + 1}/${state.queue.length})');
      return state.currentSong;
    }
    
    return null;
  }
  
  /// Jump to specific index in queue
  void jumpToIndex(int index) {
    if (index < 0 || index >= state.queue.length) {
      print('❌ Invalid queue index: $index');
      return;
    }
    
    // Add current to history if moving forward
    if (index > state.currentIndex && state.currentSong != null) {
      final newHistory = [...state.history, state.currentSong!];
      state = state.copyWith(
        currentIndex: index,
        history: newHistory,
      );
    } else {
      state = state.copyWith(currentIndex: index);
    }
    
    print('🎯 Jumped to index $index: ${state.currentSong?.title}');
  }
  
  /// Toggle shuffle mode
  void toggleShuffle() {
    final newShuffle = !state.shuffle;
    state = state.copyWith(shuffle: newShuffle);
    
    if (newShuffle) {
      _shuffleQueue();
      print('🔀 Shuffle enabled');
    } else {
      print('➡️ Shuffle disabled');
      // Note: Original order not restored, would need to track original
    }
  }
  
  /// Toggle loop mode (off -> one -> all -> off)
  void toggleLoop() {
    final nextMode = state.loopMode == LoopMode.off
        ? LoopMode.one
        : state.loopMode == LoopMode.one
        ? LoopMode.all
        : LoopMode.off;
    
    state = state.copyWith(loopMode: nextMode);
    
    final modeStr = nextMode == LoopMode.off 
        ? 'Off' 
        : nextMode == LoopMode.one 
        ? 'One' 
        : 'All';
    print('🔁 Loop mode: $modeStr');
  }
  
  /// Shuffle the queue (keeps current song at front)
  void _shuffleQueue() {
    if (state.queue.isEmpty) return;
    
    final currentSong = state.currentSong;
    final remainingSongs = [...state.queue];
    
    // Remove current song from list to shuffle
    if (currentSong != null) {
      remainingSongs.removeWhere((s) => s.id == currentSong.id);
    }
    
    // Shuffle remaining songs
    remainingSongs.shuffle();
    
    // Put current song at front, then shuffled songs
    final newQueue = currentSong != null 
        ? [currentSong, ...remainingSongs]
        : remainingSongs;
    
    state = state.copyWith(
      queue: newQueue,
      currentIndex: 0,
      history: [], // Clear history on shuffle
    );
  }
  
  /// Remove song from queue by ID
  void removeSong(String songId) {
    final newQueue = state.queue.where((s) => s.id != songId).toList();
    
    if (newQueue.isEmpty) {
      state = const QueueState();
      print('🗑️ Queue cleared (last song removed)');
      return;
    }
    
    // Adjust current index if needed
    int newIndex = state.currentIndex;
    if (state.currentSong?.id == songId) {
      // Current song was removed, stay at same index (next song)
      newIndex = state.currentIndex.clamp(0, newQueue.length - 1);
    } else if (newIndex >= newQueue.length) {
      // Index out of bounds, move to last
      newIndex = newQueue.length - 1;
    }
    
    state = state.copyWith(
      queue: newQueue,
      currentIndex: newIndex,
    );
    
    print('🗑️ Removed from queue. ${newQueue.length} songs remaining');
  }
  
  /// Clear entire queue
  void clear() {
    state = const QueueState();
    print('🗑️ Queue cleared');
  }
  
  /// Get upcoming songs (next 5)
  List<SongModel> getUpcoming({int count = 5}) {
    if (!state.hasNext) return [];
    
    final startIndex = state.currentIndex + 1;
    final endIndex = (startIndex + count).clamp(0, state.queue.length);
    
    return state.queue.sublist(startIndex, endIndex);
  }
}
