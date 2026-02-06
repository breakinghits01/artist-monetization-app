import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/story_model.dart';

/// Stories provider
final storiesProvider =
    StateNotifierProvider<StoriesNotifier, AsyncValue<List<StoryModel>>>(
      (ref) => StoriesNotifier(),
    );

class StoriesNotifier extends StateNotifier<AsyncValue<List<StoryModel>>> {
  StoriesNotifier() : super(const AsyncValue.loading()) {
    loadStories();
  }

  Future<void> loadStories() async {
    try {
      state = const AsyncValue.loading();

      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 600));

      // Mock data for now
      final stories = [
        StoryModel(
          id: '1',
          artistId: '1',
          artistName: 'DJ Alex',
          artistAvatar: '',
          genre: 'electronic',
          isLive: true,
          hasNewContent: false,
          isExclusive: false,
          items: [
            StoryItem(
              id: '1',
              type: 'video',
              mediaUrl: '',
              text: 'Live mixing session!',
              createdAt: DateTime.now(),
            ),
          ],
          createdAt: DateTime.now(),
        ),
        StoryModel(
          id: '2',
          artistId: '2',
          artistName: 'Rock Star',
          artistAvatar: '',
          genre: 'rock',
          isLive: false,
          hasNewContent: true,
          isExclusive: false,
          items: [],
          createdAt: DateTime.now(),
        ),
        StoryModel(
          id: '3',
          artistId: '3',
          artistName: 'Jazz Soul',
          artistAvatar: '',
          genre: 'jazz',
          isLive: false,
          hasNewContent: false,
          isExclusive: true,
          items: [],
          createdAt: DateTime.now(),
        ),
        StoryModel(
          id: '4',
          artistId: '4',
          artistName: 'Pop Queen',
          artistAvatar: '',
          genre: 'pop',
          isLive: false,
          hasNewContent: true,
          isExclusive: false,
          items: [],
          createdAt: DateTime.now(),
        ),
      ];

      state = AsyncValue.data(stories);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadStories();
  }
}
