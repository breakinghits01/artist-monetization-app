import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

/// Custom animated text field with floating labels and validation feedback
/// 
/// Features:
/// - Smooth floating label animation
/// - Real-time validation indicator (checkmark/error icon)
/// - Focus-based border animations
/// - Character counter (optional)
/// - Debounced validation callback
class AnimatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final bool showValidationIcon;
  final bool showCharacterCount;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final FocusNode? focusNode;
  final Future<bool> Function(String)? asyncValidator;
  final Duration asyncValidationDebounce;

  const AnimatedTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.showValidationIcon = false,
    this.showCharacterCount = false,
    this.maxLength,
    this.inputFormatters,
    this.enabled = true,
    this.focusNode,
    this.asyncValidator,
    this.asyncValidationDebounce = const Duration(milliseconds: 500),
  });

  @override
  State<AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<AnimatedTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late FocusNode _internalFocusNode;
  bool _isFocused = false;
  String? _validationError;
  bool _isValid = false;
  bool _isCheckingAsync = false;
  Timer? _asyncDebounceTimer;
  String? _availabilityMessage;
  bool? _isAvailable;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode ?? FocusNode();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _internalFocusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _asyncDebounceTimer?.cancel();
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _internalFocusNode.hasFocus;
    });
    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
      _validateField();
    }
  }

  void _onTextChange() {
    if (widget.onChanged != null) {
      widget.onChanged!(widget.controller.text);
    }
    if (_isFocused && widget.showValidationIcon) {
      _validateField();
    }
    
    // Trigger async validation if provided
    if (widget.asyncValidator != null && widget.controller.text.isNotEmpty) {
      _validateAsync();
    } else if (widget.asyncValidator != null && widget.controller.text.isEmpty) {
      // Clear availability message when field is empty
      setState(() {
        _availabilityMessage = null;
        _isAvailable = null;
        _isCheckingAsync = false;
      });
    }
  }

  void _validateField() {
    // Don't override async validation results
    if (widget.asyncValidator != null && _isAvailable != null) {
      return; // Async validation takes precedence
    }
    
    if (widget.validator != null && widget.controller.text.isNotEmpty) {
      final error = widget.validator!(widget.controller.text);
      setState(() {
        _validationError = error;
        _isValid = error == null;
      });
    } else {
      setState(() {
        _validationError = null;
        _isValid = false;
      });
    }
  }

  void _validateAsync() {
    _asyncDebounceTimer?.cancel();
    
    setState(() {
      _isCheckingAsync = true;
      _isValid = false;
      _availabilityMessage = null;
      _isAvailable = null;
    });

    _asyncDebounceTimer = Timer(widget.asyncValidationDebounce, () async {
      if (widget.asyncValidator != null) {
        try {
          // Check regular validator first - don't show availability if format is invalid
          final validationError = widget.validator?.call(widget.controller.text);
          if (validationError != null) {
            // Format is invalid, don't show availability message
            if (mounted) {
              setState(() {
                _isCheckingAsync = false;
                _isAvailable = null;
                _availabilityMessage = null;
              });
            }
            return;
          }
          
          final isAvailable = await widget.asyncValidator!(widget.controller.text);
          if (mounted) {
            setState(() {
              _isCheckingAsync = false;
              _isAvailable = isAvailable;
              if (isAvailable) {
                _isValid = true;
                _availabilityMessage = 'Available';
              } else {
                _isValid = false;
                if (widget.label.toLowerCase().contains('username')) {
                  _availabilityMessage = 'Username already taken';
                } else if (widget.label.toLowerCase().contains('email')) {
                  _availabilityMessage = 'Email already taken';
                } else {
                  _availabilityMessage = 'Already taken';
                }
              }
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isCheckingAsync = false;
              _isValid = false;
              _availabilityMessage = null;
              _isAvailable = null;
            });
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: widget.controller,
            focusNode: _internalFocusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            enabled: widget.enabled,
            maxLength: widget.maxLength,
            // Extra bottom scroll-padding so Flutter always scrolls the field
            // well clear of the soft keyboard.  120 px covers the keyboard's
            // top edge plus a comfortable margin on most mobile screens.
            scrollPadding: const EdgeInsets.only(bottom: 120),
            inputFormatters: widget.inputFormatters,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: Colors.white,
                      size: 24,
                    )
                  : null,
              suffixIcon: _buildSuffixIcon(colorScheme),
              counterText: widget.showCharacterCount ? null : '',
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.dividerColor,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.dividerColor.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.error,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.error,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: _isFocused
                  ? colorScheme.primary.withOpacity(0.03)
                  : theme.cardColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: widget.validator,
            onFieldSubmitted: widget.onSubmitted,
          ),
          // Show availability message when async validation is complete  
          if (_availabilityMessage != null && widget.asyncValidator != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12),
              child: Row(
                children: [
                  Icon(
                    _isAvailable == true ? Icons.check_circle : Icons.error,
                    size: 14,
                    color: _isAvailable == true ? const Color(0xFF00E676) : colorScheme.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _availabilityMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _isAvailable == true ? const Color(0xFF00E676) : colorScheme.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget? _buildSuffixIcon(ColorScheme colorScheme) {
    if (widget.suffixIcon != null) {
      return widget.suffixIcon;
    }

    if (!widget.showValidationIcon || widget.controller.text.isEmpty) {
      return null;
    }

    // Show loading spinner while checking async
    if (_isCheckingAsync) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      );
    }

    // For async validated fields, use _isAvailable
    if (widget.asyncValidator != null && _isAvailable != null) {
      if (_isAvailable == true) {
        return const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF00E676),
          size: 24,
        );
      } else {
        return Icon(
          Icons.cancel,
          color: colorScheme.error,
          size: 24,
        );
      }
    }

    // For non-async validated fields, use _isValid
    if (_isValid) {
      return const Icon(
        Icons.check_circle_rounded,
        color: Color(0xFF00E676),
        size: 22,
      );
    }

    if (_validationError != null) {
      return Icon(
        Icons.error_rounded,
        color: colorScheme.error,
        size: 22,
      );
    }

    return null;
  }
}
