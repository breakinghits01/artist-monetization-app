import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../player/providers/audio_player_provider.dart';
import '../../../player/widgets/audio_wave_indicator.dart';

/// Playing indicator overlay with animated wave and hover pause button
class PlayingIndicatorOverlay extends StatefulWidget {
  const PlayingIndicatorOverlay({super.key});

  @override
  State<PlayingIndicatorOverlay> createState() => _PlayingIndicatorOverlayState();
}

class _PlayingIndicatorOverlayState extends State<PlayingIndicatorOverlay> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final playerState = ref.watch(audioPlayerProvider);
        
        return Positioned.fill(
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.black.withValues(alpha: _isHovered ? 0.5 : 0.3),
              ),
              child: Stack(
                children: [
                  // Show animated wave when playing, static play icon when paused
                  if (!_isHovered || !kIsWeb)
                    Center(
                      child: playerState.isPlaying
                          ? AudioWaveIndicator(
                              isPlaying: true,
                              color: Colors.white,
                              size: 32,
                            )
                          : Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                    ),
                  // Pause button (only on hover for web, or always for mobile)
                  if (_isHovered && kIsWeb)
                    Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            ref.read(audioPlayerProvider.notifier).playPause();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              playerState.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
