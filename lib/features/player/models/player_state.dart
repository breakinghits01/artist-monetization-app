import 'package:just_audio/just_audio.dart';

/// Player state model
class PlayerState {
  final bool isPlaying;
  final bool isLoading;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final double speed;
  final LoopMode loopMode;
  final bool shuffleMode;

  const PlayerState({
    this.isPlaying = false,
    this.isLoading = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1.0,
    this.loopMode = LoopMode.off,
    this.shuffleMode = false,
  });

  /// Get progress as a percentage (0.0 - 1.0)
  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  /// Format position as MM:SS
  String get formattedPosition {
    return _formatDuration(position);
  }

  /// Format duration as MM:SS
  String get formattedDuration {
    return _formatDuration(duration);
  }

  /// Format remaining time as -MM:SS
  String get formattedRemaining {
    final remaining = duration - position;
    return '-${_formatDuration(remaining)}';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  PlayerState copyWith({
    bool? isPlaying,
    bool? isLoading,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    double? speed,
    LoopMode? loopMode,
    bool? shuffleMode,
  }) {
    return PlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      loopMode: loopMode ?? this.loopMode,
      shuffleMode: shuffleMode ?? this.shuffleMode,
    );
  }
}

/// Token earning state
class TokenEarnState {
  final int tokensEarned;
  final double progress; // 0.0 - 1.0
  final bool isEligible; // Has listened to 80%+
  final bool hasRewarded;

  const TokenEarnState({
    this.tokensEarned = 0,
    this.progress = 0.0,
    this.isEligible = false,
    this.hasRewarded = false,
  });

  TokenEarnState copyWith({
    int? tokensEarned,
    double? progress,
    bool? isEligible,
    bool? hasRewarded,
  }) {
    return TokenEarnState(
      tokensEarned: tokensEarned ?? this.tokensEarned,
      progress: progress ?? this.progress,
      isEligible: isEligible ?? this.isEligible,
      hasRewarded: hasRewarded ?? this.hasRewarded,
    );
  }
}
