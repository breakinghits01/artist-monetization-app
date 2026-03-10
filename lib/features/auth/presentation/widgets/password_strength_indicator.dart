import 'package:flutter/material.dart';

/// Password strength calculator and visual indicator
/// 
/// Calculates strength based on:
/// - Length (8+ characters)
/// - Uppercase letters
/// - Lowercase letters  
/// - Numbers
/// - Special characters
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool showRequirements;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showRequirements = true,
  });

  /// Calculate password strength score (0-4)
  PasswordStrength _calculateStrength() {
    if (password.isEmpty) {
      return PasswordStrength.empty;
    }

    int score = 0;
    
    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    
    // Character type checks
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    // Map score to strength
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.fair;
    if (score <= 5) return PasswordStrength.good;
    return PasswordStrength.strong;
  }

  @override
  Widget build(BuildContext context) {
    final strength = _calculateStrength();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strength bar
        if (password.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: [
                        strength.color,
                        strength.color.withOpacity(0.3),
                      ],
                      stops: [strength.progress, strength.progress],
                    ),
                    color: theme.dividerColor.withOpacity(0.2),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: theme.textTheme.bodySmall!.copyWith(
                  color: strength.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                child: Text(strength.label),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Requirements checklist
        if (showRequirements && password.isNotEmpty) ...[
          _RequirementItem(
            label: '8+ characters',
            isMet: password.length >= 8,
          ),
          _RequirementItem(
            label: 'Uppercase letter',
            isMet: password.contains(RegExp(r'[A-Z]')),
          ),
          _RequirementItem(
            label: 'Lowercase letter',
            isMet: password.contains(RegExp(r'[a-z]')),
          ),
          _RequirementItem(
            label: 'Number',
            isMet: password.contains(RegExp(r'[0-9]')),
          ),
          _RequirementItem(
            label: 'Special character (!@#\$%^&*)',
            isMet: password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]')),
          ),
        ],
      ],
    );
  }
}

/// Individual requirement check item
class _RequirementItem extends StatelessWidget {
  final String label;
  final bool isMet;

  const _RequirementItem({
    required this.label,
    required this.isMet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMet 
                  ? const Color(0xFF00E676) 
                  : theme.dividerColor.withValues(alpha: 0.3),
            ),
            child: isMet
                ? const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: isMet
                  ? theme.textTheme.bodyMedium?.color
                  : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              fontWeight: isMet ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// Password strength enum with associated properties
enum PasswordStrength {
  empty(
    label: '',
    color: Colors.transparent,
    progress: 0.0,
  ),
  weak(
    label: 'Weak',
    color: Color(0xFFFF4444),
    progress: 0.25,
  ),
  fair(
    label: 'Fair',
    color: Color(0xFFFFB300),
    progress: 0.5,
  ),
  good(
    label: 'Good',
    color: Color(0xFF00BCD4),
    progress: 0.75,
  ),
  strong(
    label: 'Strong',
    color: Color(0xFF00E676),
    progress: 1.0,
  );

  final String label;
  final Color color;
  final double progress;

  const PasswordStrength({
    required this.label,
    required this.color,
    required this.progress,
  });
}
