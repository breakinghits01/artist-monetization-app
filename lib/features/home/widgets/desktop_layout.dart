import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../player/widgets/player_wrapper.dart';
import '../../player/widgets/mini_player.dart';
import '../../player/providers/audio_player_provider.dart';
import 'web_sidebar.dart';
import 'web_top_bar.dart';

/// Desktop layout wrapper with sidebar and top bar
/// Used as shell for desktop routes
class DesktopLayout extends ConsumerWidget {
  final Widget child;

  const DesktopLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final isPlayerExpanded = ref.watch(playerExpandedProvider);

    return PlayerWrapper(
      child: Scaffold(
        body: Row(
          children: [
            const WebSidebar(),
            Expanded(
              child: Column(
                children: [
                  const WebTopBar(),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
        bottomSheet: currentSong != null && !isPlayerExpanded
            ? const MiniPlayer()
            : null,
      ),
    );
  }
}
