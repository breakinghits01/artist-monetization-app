import 'dart:ui';
import 'package:flutter/material.dart';

/// Glassmorphism container matching app theme
/// Pink/Magenta primary, Cyan secondary, Navy background
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blurStrength;
  final double opacity;
  final Color? tintColor;
  final Border? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blurStrength = 20.0,
    this.opacity = 0.1,
    this.tintColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use theme colors for tint
    final defaultTint = isDark
        ? theme.colorScheme.primary.withOpacity(0.1)
        : Colors.white.withOpacity(0.7);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: border ??
            Border.all(
              color: theme.colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurStrength,
            sigmaY: blurStrength,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tintColor ?? defaultTint,
                  (tintColor ?? defaultTint).withOpacity(opacity * 0.5),
                ],
              ),
              borderRadius: borderRadius ?? BorderRadius.circular(16),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
