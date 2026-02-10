import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_player_provider.dart';
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
        // Full player (when expanded) with smooth animation
        if (isExpanded)
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                // Slide and fade transition
                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ));

                return SlideTransition(
                  position: offsetAnimation,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: isExpanded
                  ? const FullPlayerScreen(key: ValueKey('fullPlayer'))
                  : const SizedBox.shrink(key: ValueKey('noPlayer')),
            ),
          ),
      ],
    );
  }
}
