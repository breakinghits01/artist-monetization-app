import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/dashboard_card_model.dart';
import '../../../artist/models/artist_model.dart';
import '../../../artist/widgets/artist_profile_card.dart';

/// Artist spotlight card widget - integrates with real artist data
class ArtistSpotlightCard extends ConsumerWidget {
  final DashboardCardModel card;

  const ArtistSpotlightCard({super.key, required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistId = card.metadata?['artistId'] as String?;

    // If we have artist ID in metadata, use it to build the card
    if (artistId != null) {
      // Create artist model from card data
      final artist = ArtistModel(
        id: artistId,
        username: card.title,
        profilePicture: card.imageUrl?.isNotEmpty == true ? card.imageUrl : null,
        followerCount: card.metadata?['followers'] as int? ?? 0,
        followingCount: 0,
        songCount: card.metadata?['songs'] as int? ?? 0,
      );

      return ArtistProfileCard(
        artist: artist,
        onTap: () {
          // TODO: Navigate to artist profile screen
          print('Navigate to artist: $artistId');
        },
      );
    }

    // Fallback to loading state if no artist data
    return Card(
      child: Container(
        height: 200,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      ),
    );
  }
}

