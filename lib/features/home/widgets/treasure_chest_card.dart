import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/token_icon.dart';
import '../models/treasure_chest_model.dart';
import '../providers/treasure_provider.dart';

/// Animated treasure chest card with countdown and rewards
class TreasureChestCard extends ConsumerStatefulWidget {
  final TreasureChestModel chest;

  const TreasureChestCard({super.key, required this.chest});

  @override
  ConsumerState<TreasureChestCard> createState() => _TreasureChestCardState();
}

class _TreasureChestCardState extends ConsumerState<TreasureChestCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;
  Timer? _countdownTimer;
  Duration? _remainingTime;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticInOut),
    );

    if (widget.chest.isReady) {
      _animationController.repeat(reverse: true);
    }

    _startCountdown();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _countdownTimer?.cancel();
    _countdownTimer = null;
    super.dispose();
  }

  void _startCountdown() {
    _remainingTime = widget.chest.timeRemaining;
    
    // OPTIMIZATION: Only update UI once per second, not on every tick
    // Use a ValueNotifier or similar for better performance in the future
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final newRemaining = widget.chest.timeRemaining;
      
      // Only call setState if value actually changed
      if (newRemaining != _remainingTime) {
        setState(() {
          _remainingTime = newRemaining;
          if (_remainingTime == Duration.zero && !widget.chest.isReady) {
            _animationController.repeat(reverse: true);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, widget.chest.isReady ? -_bounceAnimation.value : 0),
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getGradientColors(theme, isDark),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Animated background pattern
              Positioned.fill(
                child: CustomPaint(
                  painter: _TreasurePatternPainter(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Text('🎁', style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.chest.name,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.chest.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Treasure chest visual
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: widget.chest.isReady
                              ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            widget.chest.isOpened ? '✅' : '🏴‍☠️',
                            style: const TextStyle(fontSize: 64),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Status section
                    if (!widget.chest.isOpened) ...[
                      if (widget.chest.isReady)
                        _buildReadyState(theme)
                      else
                        _buildLockedState(theme),
                    ] else
                      _buildOpenedState(theme),

                    const SizedBox(height: 16),

                    // Rewards preview
                    _buildRewardsPreview(theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientColors(ThemeData theme, bool isDark) {
    if (widget.chest.isReady) {
      return [
        const Color(0xFFFFA500), // Orange-gold (less bright)
        const Color(0xFFFF8C00), // Dark orange
      ];
    } else if (widget.chest.isOpened) {
      return [theme.colorScheme.primary, theme.colorScheme.secondary];
    } else {
      return [
        const Color(0xFF6B4423), // Bronze
        const Color(0xFF8B5A3C),
      ];
    }
  }

  Widget _buildReadyState(ThemeData theme) {
    return Column(
      children: [
        Text(
          '✨ Ready to Open! ✨',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _openChest(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Open Chest',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLockedState(ThemeData theme) {
    return Column(
      children: [
        Text(
          _formatTimeRemaining(),
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Until unlock',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        if (widget.chest.tokensCost != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _unlockWithTokens(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Unlock Now: ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${widget.chest.tokensCost}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const TokenIcon(size: 20, withShadow: false),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOpenedState(ThemeData theme) {
    return Center(
      child: Text(
        'Already Opened',
        style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
      ),
    );
  }

  Widget _buildRewardsPreview(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Possible Rewards:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.chest.rewards.map((reward) {
              return Chip(
                avatar: reward.type == 'tokens'
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: TokenIcon(size: 20, withShadow: false),
                      )
                    : Text(reward.emoji),
                label: Text(reward.description),
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatTimeRemaining() {
    if (_remainingTime == null) return '00:00:00';

    final hours = _remainingTime!.inHours;
    final minutes = _remainingTime!.inMinutes.remainder(60);
    final seconds = _remainingTime!.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  void _openChest() {
    ref.read(treasureProvider.notifier).openChest(widget.chest.id);
    _showRewardsDialog();
  }

  void _unlockWithTokens() {
    ref.read(treasureProvider.notifier).unlockWithTokens(widget.chest.id);
  }

  void _showRewardsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Congratulations!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You received:'),
            const SizedBox(height: 16),
            ...widget.chest.rewards.map((reward) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    if (reward.type == 'tokens')
                      const TokenIcon(size: 24, withShadow: false)
                    else
                      Text(reward.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(reward.description)),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for treasure pattern background
class _TreasurePatternPainter extends CustomPainter {
  final Color color;

  _TreasurePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw diagonal lines pattern
    for (double i = 0; i < size.width + size.height; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(0, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
