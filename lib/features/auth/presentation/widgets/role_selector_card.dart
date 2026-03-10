import 'package:flutter/material.dart';

/// Interactive role selector card with smooth animations
/// 
/// Features:
/// - Large, tappable card with icon and description
/// - Scale animation on selection
/// - Border highlight effect
/// - Smooth color transitions
class RoleSelectorCard extends StatefulWidget {
  final String role;
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? accentColor;

  const RoleSelectorCard({
    super.key,
    required this.role,
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.accentColor,
  });

  @override
  State<RoleSelectorCard> createState() => _RoleSelectorCardState();
}

class _RoleSelectorCardState extends State<RoleSelectorCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveAccentColor = widget.accentColor ?? colorScheme.primary;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? effectiveAccentColor.withOpacity(0.08)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? effectiveAccentColor
                  : theme.dividerColor.withOpacity(0.3),
              width: widget.isSelected ? 2.5 : 1.5,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: effectiveAccentColor.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? effectiveAccentColor.withOpacity(0.15)
                      : theme.dividerColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: 48,
                  color: widget.isSelected
                      ? effectiveAccentColor
                      : Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: widget.isSelected
                      ? effectiveAccentColor
                      : theme.textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              
              // Description
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                  height: 1.4,
                ),
              ),
              
              // Selected indicator
              if (widget.isSelected) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: effectiveAccentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Selected',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Role data model
class RoleData {
  final String role;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;

  const RoleData({
    required this.role,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
  });

  static const fan = RoleData(
    role: 'fan',
    title: 'Fan',
    description: 'Discover and support your favorite artists',
    icon: Icons.favorite_rounded,
    accentColor: Color(0xFFE91E63),
  );

  static const artist = RoleData(
    role: 'artist',
    title: 'Artist',
    description: 'Share your music and connect with fans',
    icon: Icons.mic_rounded,
    accentColor: Color(0xFF9C27B0),
  );

  static const List<RoleData> all = [fan, artist];
}
