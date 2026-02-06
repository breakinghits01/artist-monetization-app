import 'package:flutter/material.dart';
import '../models/artist_model.dart';
import './follow_button.dart';

class ArtistCard extends StatelessWidget {
  final ArtistModel artist;
  final VoidCallback? onTap;
  final VoidCallback? onFollowChanged;

  const ArtistCard({
    super.key,
    required this.artist,
    this.onTap,
    this.onFollowChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? null : Border.all(color: Colors.grey[300]!),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile picture
              CircleAvatar(
                radius: 30,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                backgroundImage: artist.profilePicture != null
                    ? NetworkImage(artist.profilePicture!)
                    : null,
                child: artist.profilePicture == null
                    ? Text(
                        artist.initials,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // Artist info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Username
                    Text(
                      artist.username,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Bio
                    if (artist.bio != null && artist.bio!.isNotEmpty) ...[
                      Text(
                        artist.bio!,
                        style: TextStyle(
                          color: isDark ? Colors.white.withOpacity(0.6) : Colors.black54,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Stats
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 16,
                              color: isDark ? Colors.white.withOpacity(0.6) : Colors.black54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${artist.formattedFollowerCount}',
                              style: TextStyle(
                                color: isDark ? Colors.white.withOpacity(0.6) : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.music_note_outlined,
                              size: 16,
                              color: isDark ? Colors.white.withOpacity(0.6) : Colors.black54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${artist.formattedSongCount}',
                              style: TextStyle(
                                color: isDark ? Colors.white.withOpacity(0.6) : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (artist.hasExclusiveContent)
                          Icon(
                            Icons.lock,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Follow button
              FollowButton(
                artist: artist,
                onFollowChanged: onFollowChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
