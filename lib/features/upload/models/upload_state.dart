import 'upload_session.dart';
import '../../player/models/song_model.dart';

/// Upload feature state
sealed class UploadState {
  const UploadState();
  
  const factory UploadState.idle() = UploadStateIdle;
  const factory UploadState.validating({required String fileName}) = UploadStateValidating;
  const factory UploadState.uploading({required UploadSession session}) = UploadStateUploading;
  const factory UploadState.processing({required UploadSession session}) = UploadStateProcessing;
  const factory UploadState.completed({required UploadSession session}) = UploadStateCompleted;
  const factory UploadState.published({required SongModel song}) = UploadStatePublished;
  const factory UploadState.error({required String message, UploadSession? session}) = UploadStateError;
  
  T when<T>({
    required T Function() idle,
    required T Function(String fileName) validating,
    required T Function(UploadSession session) uploading,
    required T Function(UploadSession session) processing,
    required T Function(UploadSession session) completed,
    required T Function(SongModel song) published,
    required T Function(String message, UploadSession? session) error,
  }) {
    final state = this;
    if (state is UploadStateIdle) return idle();
    if (state is UploadStateValidating) return validating(state.fileName);
    if (state is UploadStateUploading) return uploading(state.session);
    if (state is UploadStateProcessing) return processing(state.session);
    if (state is UploadStateCompleted) return completed(state.session);
    if (state is UploadStatePublished) return published(state.song);
    if (state is UploadStateError) return error(state.message, state.session);
    throw Exception('Unknown state: $state');
  }
}

class UploadStateIdle extends UploadState {
  const UploadStateIdle();
}

class UploadStateValidating extends UploadState {
  final String fileName;
  const UploadStateValidating({required this.fileName});
}

class UploadStateUploading extends UploadState {
  final UploadSession session;
  const UploadStateUploading({required this.session});
}

class UploadStateProcessing extends UploadState {
  final UploadSession session;
  const UploadStateProcessing({required this.session});
}

class UploadStateCompleted extends UploadState {
  final UploadSession session;
  const UploadStateCompleted({required this.session});
}

class UploadStatePublished extends UploadState {
  final SongModel song;
  const UploadStatePublished({required this.song});
}

class UploadStateError extends UploadState {
  final String message;
  final UploadSession? session;
  const UploadStateError({required this.message, this.session});
}
