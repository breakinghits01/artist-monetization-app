import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animated audio waveform indicator that shows when music is playing
class AudioWaveIndicator extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  final double size;

  const AudioWaveIndicator({
    super.key,
    required this.isPlaying,
    required this.color,
    this.size = 24,
  });

  @override
  State<AudioWaveIndicator> createState() => _AudioWaveIndicatorState();
}

class _AudioWaveIndicatorState extends State<AudioWaveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AudioWaveIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _WaveformPainter(
              animation: _controller.value,
              color: widget.color,
              isPlaying: widget.isPlaying,
            ),
          );
        },
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double animation;
  final Color color;
  final bool isPlaying;

  _WaveformPainter({
    required this.animation,
    required this.color,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final barCount = 4;
    final spacing = size.width / (barCount + 1);
    final maxHeight = size.height * 0.8;
    final minHeight = size.height * 0.2;

    for (int i = 0; i < barCount; i++) {
      final x = spacing * (i + 1);
      
      // Each bar has different phase offset for wave effect
      final phase = (animation * 2 * math.pi) + (i * math.pi / 2);
      
      // Calculate height using sine wave with different frequencies
      final heightFactor = isPlaying
          ? (math.sin(phase) * 0.5 + 0.5) // 0 to 1
          : 0.3; // Static height when paused
      
      final barHeight = minHeight + (maxHeight - minHeight) * heightFactor;
      
      // Draw bar centered vertically
      final top = (size.height - barHeight) / 2;
      final bottom = top + barHeight;
      
      canvas.drawLine(
        Offset(x, top),
        Offset(x, bottom),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) {
    return animation != oldDelegate.animation || 
           isPlaying != oldDelegate.isPlaying ||
           color != oldDelegate.color;
  }
}
