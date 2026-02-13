import 'package:flutter/material.dart';
import '../../core/theme/app_colors_extension.dart';

/// Custom token icon widget - yellow circular coin
/// Colors adapt to theme automatically
class TokenIcon extends StatelessWidget {
  final double size;
  final bool withShadow;

  const TokenIcon({super.key, this.size = 24, this.withShadow = true});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [colorScheme.tokenPrimary, colorScheme.tokenSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: withShadow
            ? [
                BoxShadow(
                  color: colorScheme.tokenPrimary.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          'T',
          style: TextStyle(
            fontSize: size * 0.56, // Proportional to size
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
