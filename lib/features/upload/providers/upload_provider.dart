import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/upload_state.dart';
import '../models/upload_session.dart';
import '../models/song_metadata.dart';
import '../services/upload_service.dart';
import '../services/file_picker_service.dart';
import '../../player/models/song_model.dart';
import '../../profile/providers/user_songs_provider.dart';
import '../../auth/providers/auth_provider.dart';

/// Upload service provider
final uploadServiceProvider = Provider<UploadService>((ref) {
  return UploadService();
});

/// Upload state provider
final uploadProvider = StateNotifierProvider<UploadNotifier, UploadState>((ref) {
  return UploadNotifier(ref);
});

/// Upload notifier
class UploadNotifier extends StateNotifier<UploadState> {
  final Ref _ref;

  UploadNotifier(this._ref) : super(const UploadState.idle());

  /// Reset to idle state
  void reset() {
    state = const UploadState.idle();
  }

  /// Initiate upload from file pick result
  Future<void> initiateUpload(FilePickResult result) async {
    try {
      state = UploadState.validating(fileName: result.name);

      final uploadService = _ref.read(uploadServiceProvider);
      final session = await uploadService.initiateUpload(result.path, fileBytes: result.bytes);

      state = UploadState.uploading(session: session);

      // Start upload with progress tracking
      await _startUpload(session, result.path);
    } catch (e) {
      state = UploadState.error(message: e.toString());
    }
  }

  /// Start upload with progress tracking
  Future<void> _startUpload(UploadSession session, String filePath) async {
    try {
      final uploadService = _ref.read(uploadServiceProvider);
      final stream = uploadService.uploadWithProgress(session, filePath);

      await for (final progress in stream) {
        // Update progress
        final updatedSession = session.copyWith(
          uploadProgress: progress,
          uploadStatus: progress >= 100 ? 'processing' : 'uploading',
        );

        if (progress >= 100) {
          state = UploadState.processing(session: updatedSession);
          
          // Process audio
          await uploadService.processAudio(updatedSession);
          
          // Mark as completed
          final completedSession = updatedSession.copyWith(
            uploadStatus: 'completed',
            completedAt: DateTime.now(),
          );
          state = UploadState.completed(session: completedSession);
        } else {
          state = UploadState.uploading(session: updatedSession);
        }
      }
    } catch (e) {
      state = UploadState.error(
        message: 'Upload failed: ${e.toString()}',
        session: session,
      );
    }
  }

  /// Submit metadata and create song
  Future<void> submitMetadata(UploadSession session, SongMetadata metadata) async {
    try {
      final uploadService = _ref.read(uploadServiceProvider);
      final songData = await uploadService.createSong(session, metadata);

      // Get actual user info from auth provider
      final currentUser = _ref.read(currentUserProvider);
      final userId = currentUser?['_id'] ?? currentUser?['id'] ?? 'unknown';
      final userName = currentUser?['username'] ?? currentUser?['name'] ?? 'Current User';

      // Convert to SongModel
      final song = SongModel(
        id: songData['id'],
        title: songData['title'],
        artist: userName,
        artistId: userId,
        albumArt: songData['coverArt'] ?? 'https://via.placeholder.com/300',
        duration: Duration(seconds: (songData['duration'] ?? 180) as int),
        audioUrl: songData['audioUrl'],
        genre: songData['genre'],
        tokenReward: metadata.price,
      );

      state = UploadState.published(song: song);

      // Add song to user's song list
      _ref.read(userSongsProvider.notifier).addSong(song);
    } catch (e) {
      state = UploadState.error(
        message: 'Failed to publish song: ${e.toString()}',
        session: session,
      );
    }
  }

  /// Save as draft
  Future<void> saveDraft(UploadSession session, SongMetadata metadata) async {
    try {
      final uploadService = _ref.read(uploadServiceProvider);
      final songData = await uploadService.createSong(
        session,
        metadata,
        isDraft: true,
      );

      // Convert to SongModel
      final song = SongModel(
        id: songData['id'],
        title: songData['title'],
        artist: 'Current User',
        artistId: 'current-user-id',
        albumArt: songData['coverArt'] ?? 'https://via.placeholder.com/300',
        duration: Duration(seconds: songData['duration'] as int),
        audioUrl: songData['audioUrl'],
        genre: songData['genre'],
        tokenReward: metadata.price,
      );

      // Add song to user's song list
      _ref.read(userSongsProvider.notifier).addSong(song);
      
      state = UploadState.published(song: song);
    } catch (e) {
      state = UploadState.error(
        message: 'Failed to save draft: ${e.toString()}',
        session: session,
      );
    }
  }

  /// Cancel upload
  Future<void> cancelUpload() async {
    try {
      final currentState = state;
      if (currentState is UploadStateUploading || currentState is UploadStateProcessing) {
        final uploadService = _ref.read(uploadServiceProvider);
        final session = currentState is UploadStateUploading 
            ? currentState.session 
            : (currentState as UploadStateProcessing).session;
        
        await uploadService.cancelUpload(session);
        state = const UploadState.idle();
      }
    } catch (e) {
      state = UploadState.error(message: 'Failed to cancel upload: ${e.toString()}');
    }
  }
}
