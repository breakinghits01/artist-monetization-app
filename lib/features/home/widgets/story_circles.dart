import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/story_model.dart';
import '../providers/story_provider.dart';

/// Horizontal scrolling story circles with live indicators
class StoryCircles extends ConsumerWidget {
  const StoryCircles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(storiesProvider);

    return stories.when(
      data: (storiesList) {
        if (storiesList.isEmpty) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: storiesList.length + 1, // +1 for "Add" button
            itemBuilder: (context, index) {
              if (index == storiesList.length) {
                return _AddStoryCircle();
              }
              return _StoryCircle(story: storiesList[index]);
            },
          ),
        );
      },
      loading: () => SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 6,
          itemBuilder: (context, index) => _StoryCircleSkeleton(),
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

/// Individual story circle
class _StoryCircle extends StatelessWidget {
  final StoryModel story;

  const _StoryCircle({required this.story});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          // Open story viewer
          _showStory(context);
        },
        borderRadius: BorderRadius.circular(50),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Story ring with avatar
            Stack(
              children: [
                // Gradient ring
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _getGradient(theme),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.5),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.scaffoldBackgroundColor,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2.5),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: theme.colorScheme.surface,
                          backgroundImage: story.artistAvatar.isNotEmpty
                              ? NetworkImage(story.artistAvatar)
                              : null,
                          child: story.artistAvatar.isEmpty
                              ? Text(
                                  story.artistName[0].toUpperCase(),
                                  style: theme.textTheme.titleLarge,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                // Live indicator
                if (story.isLive)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // New content badge
                if (story.hasNewContent && !story.isLive)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700), // Gold
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                // Exclusive lock
                if (story.isExclusive)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.lock,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // Artist name
            SizedBox(
              width: 68,
              child: Text(
                story.artistName,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Gradient _getGradient(ThemeData theme) {
    if (story.isLive) {
      // Pulsing red gradient for live
      return const LinearGradient(
        colors: [Colors.red, Color(0xFFFF6B6B), Colors.red],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (story.hasNewContent) {
      // Gold gradient for new content
      return const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFFFB300)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (story.isExclusive) {
      // Premium gradient
      return LinearGradient(
        colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      // Default genre-based gradient
      return LinearGradient(
        colors: [
          _parseColor(story.genreColor),
          _parseColor(story.genreColor).withOpacity(0.6),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  void _showStory(BuildContext context) {
    // TODO: Implement story viewer
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(story.artistName),
        content: Text(
          'Story viewer coming soon!\n\n${story.items.length} items',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Add story circle (for artist accounts)
class _AddStoryCircle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          // Open story creator
        },
        borderRadius: BorderRadius.circular(50),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Icon(
                Icons.add,
                color: theme.colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Story circle loading skeleton
class _StoryCircleSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.onSurface.withOpacity(0.05),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 50,
            height: 10,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
