import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_player_provider.dart';
import 'mini_player.dart';
import 'full_player_screen.dart';

/// Wrapper that handles mini/full player display
class PlayerWrapper extends ConsumerWidget {
  final Widget child;

  const PlayerWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(playerExpandedProvider);

    return Stack(
      children: [
        child,
        // Full player (when expanded)
        if (isExpanded)
          const Positioned.fill(
            child: FullPlayerScreen(),
          ),
      ],
    );
  }
}
