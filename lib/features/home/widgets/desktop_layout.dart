import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../player/widgets/player_wrapper.dart';
import '../../player/widgets/mini_player_desktop.dart';
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
        body: Stack(
          children: [
            Row(
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
            // Mini player positioned at bottom, starting after sidebar
            if (currentSong != null && !isPlayerExpanded)
              Positioned(
                left: 280, // Start after sidebar width
                right: 0,
                bottom: 0,
                child: const MiniPlayerDesktop(),
              ),
          ],
        ),
      ),
    );
  }
}
