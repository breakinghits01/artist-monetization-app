import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/artist_model.dart';
import '../providers/follow_provider.dart';

class FollowButton extends ConsumerStatefulWidget {
  final ArtistModel artist;
  final VoidCallback? onFollowChanged;

  const FollowButton({
    super.key,
    required this.artist,
    this.onFollowChanged,
  });

  @override
  ConsumerState<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<FollowButton> {
  bool _isLoading = false;

  Future<void> _toggleFollow(bool currentStatus) async {
    setState(() => _isLoading = true);

    try {
      final followActions = ref.read(followActionProvider);

      if (currentStatus) {
        await followActions.unfollowArtist(widget.artist.id);
      } else {
        await followActions.followArtist(widget.artist.id);
      }

      widget.onFollowChanged?.call();
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().contains('401') || e.toString().contains('authorized')
            ? 'Please log in to follow artists'
            : 'Failed to ${currentStatus ? 'unfollow' : 'follow'} artist';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final followStatusAsync = ref.watch(artistFollowStatusProvider(widget.artist.id));

    return followStatusAsync.when(
      data: (isFollowing) {
        final theme = Theme.of(context);
        return Container(
          height: 36,
          width: 90,
          decoration: BoxDecoration(
            color: isFollowing 
                ? (theme.brightness == Brightness.dark ? const Color(0xFF2A3150) : Colors.grey[200])
                : theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
            border: isFollowing
                ? Border.all(
                    color: theme.brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.5),
                    width: 1,
                  )
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : () => _toggleFollow(isFollowing),
              borderRadius: BorderRadius.circular(20),
              child: Center(
                child: _isLoading
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isFollowing
                                ? (theme.brightness == Brightness.dark ? Colors.white : Colors.black54)
                                : Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        isFollowing ? 'Following' : 'Follow',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isFollowing
                              ? (theme.brightness == Brightness.dark ? Colors.white : Colors.black87)
                              : Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
      loading: () {
        final theme = Theme.of(context);
        return Container(
          height: 36,
          width: 90,
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark 
                ? const Color(0xFF2A3150) 
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.brightness == Brightness.dark ? Colors.white : Colors.black54,
                ),
              ),
            ),
          ),
        );
      },
      error: (error, __) {
        final theme = Theme.of(context);
        return Container(
          height: 36,
          width: 90,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _toggleFollow(false),
              borderRadius: BorderRadius.circular(20),
              child: const Center(
                child: Text(
                  'Follow',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
