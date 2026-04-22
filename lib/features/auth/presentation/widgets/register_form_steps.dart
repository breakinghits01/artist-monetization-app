import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/services/username_availability_service.dart';
import 'animated_text_field.dart';
import 'password_strength_indicator.dart';
import 'role_selector_card.dart';

/// Multi-step registration form with smooth page transitions
/// 
/// Steps:
/// 1. Role Selection (Fan/Artist)
/// 2. Basic Information (Username, Email)
/// 3. Security (Password, Confirm)
class RegisterFormSteps extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final ValueNotifier<String> selectedRole;
  final VoidCallback onSubmit;
  final bool isLoading;

  const RegisterFormSteps({
    super.key,
    required this.formKey,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.selectedRole,
    required this.onSubmit,
    required this.isLoading,
  });

  @override
  State<RegisterFormSteps> createState() => _RegisterFormStepsState();
}

class _RegisterFormStepsState extends State<RegisterFormSteps> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 3;
  final AvailabilityService _availabilityService = AvailabilityService();

  // Track validation state for enabling/disabling continue button
  bool _isUsernameAvailable = false;
  bool _isEmailAvailable = false;
  bool _isCheckingUsername = false;
  bool _isCheckingEmail = false;

  // Tracks the last known keyboard height so we can detect when the
  // keyboard has fully appeared and trigger an ensureVisible scroll.
  double _lastViewInsets = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    // Fire only when the keyboard is opening (viewInsets grows).
    // At this point the layout has already been updated, so
    // Scrollable.ensureVisible will measure correct positions.
    if (viewInsets > _lastViewInsets) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final focus = FocusManager.instance.primaryFocus;
        if (focus?.context != null) {
          // Walk all scrollable ancestors (SingleChildScrollView inside
          // the PageView page, then PageView itself) and scroll each
          // one so the focused field is centred in the visible area.
          Scrollable.ensureVisible(
            focus!.context!,
            alignment: 0.5,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          );
        }
      });
    }
    _lastViewInsets = viewInsets;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _availabilityService.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      // Validate current step before proceeding
      if (_currentStep == 1 && !_validateBasicInfo()) {
        return;
      }

      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Final step - submit form
      if (widget.formKey.currentState!.validate()) {
        widget.onSubmit();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateBasicInfo() {
    // Validate username
    if (widget.usernameController.text.isEmpty) {
      _showError('Please enter a username');
      return false;
    }
    if (widget.usernameController.text.length < AppConstants.minUsernameLength) {
      _showError('Username must be at least ${AppConstants.minUsernameLength} characters');
      return false;
    }
    if (!_isUsernameAvailable) {
      _showError('Username is already taken');
      return false;
    }

    // Validate email
    if (widget.emailController.text.isEmpty) {
      _showError('Please enter your email');
      return false;
    }
    if (!AppConstants.emailRegex.hasMatch(widget.emailController.text)) {
      _showError('Please enter a valid email');
      return false;
    }
    if (!_isEmailAvailable) {
      _showError('Email is already taken');
      return false;
    }

    return true;
  }

  /// Check if basic info step can proceed (for button state)
  bool get _canProceedFromBasicInfo {
    return widget.usernameController.text.isNotEmpty &&
           widget.emailController.text.isNotEmpty &&
           _isUsernameAvailable &&
           _isEmailAvailable &&
           !_isCheckingUsername &&
           !_isCheckingEmail;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress indicator
        _buildProgressIndicator(),
        const SizedBox(height: 32),

        // Form steps
        Expanded(
          child: Form(
            key: widget.formKey,
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                _buildRoleSelectionStep(),
                _buildBasicInfoStep(),
                _buildSecurityStep(),
              ],
            ),
          ),
        ),

        // Navigation buttons
        const SizedBox(height: 24),
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(
        _totalSteps,
        (index) => Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: index < _totalSteps - 1 ? 8 : 0,
            ),
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: index <= _currentStep
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose Your Role',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select how you\'d like to use the platform',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 32),
          
          // Role cards
          ValueListenableBuilder<String>(
            valueListenable: widget.selectedRole,
            builder: (context, selectedRole, child) {
              return Row(
                children: [
                  Expanded(
                    child: RoleSelectorCard(
                      role: RoleData.fan.role,
                      title: RoleData.fan.title,
                      description: RoleData.fan.description,
                      icon: RoleData.fan.icon,
                      accentColor: RoleData.fan.accentColor,
                      isSelected: selectedRole == RoleData.fan.role,
                      onTap: () => widget.selectedRole.value = RoleData.fan.role,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: RoleSelectorCard(
                      role: RoleData.artist.role,
                      title: RoleData.artist.title,
                      description: RoleData.artist.description,
                      icon: RoleData.artist.icon,
                      accentColor: RoleData.artist.accentColor,
                      isSelected: selectedRole == RoleData.artist.role,
                      onTap: () => widget.selectedRole.value = RoleData.artist.role,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Basic Information',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us a bit about yourself',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 32),

          AnimatedTextField(
            controller: widget.usernameController,
            label: 'Username',
            hint: 'Choose a unique username',
            prefixIcon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            showValidationIcon: true,
            asyncValidator: (username) async {
              setState(() => _isCheckingUsername = true);
              final available = await _availabilityService.checkUsernameAvailability(username);
              setState(() {
                _isUsernameAvailable = available;
                _isCheckingUsername = false;
              });
              return available;
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              if (value.length < AppConstants.minUsernameLength) {
                return 'Too short';
              }
              if (!AppConstants.usernameRegex.hasMatch(value)) {
                return 'Letters, numbers, underscore only';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          AnimatedTextField(
            controller: widget.emailController,
            label: 'Email Address',
            hint: 'your@email.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            showValidationIcon: true,
            asyncValidator: (email) async {
              setState(() => _isCheckingEmail = true);
              final available = await _availabilityService.checkEmailAvailability(email);
              setState(() {
                _isEmailAvailable = available;
                _isCheckingEmail = false;
              });
              return available;
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              if (!AppConstants.emailRegex.hasMatch(value)) {
                return 'Invalid email format';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Secure Your Account',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a strong password',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 32),

          ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.passwordController,
            builder: (context, value, child) {
              return Column(
                children: [
                  AnimatedTextField(
                    controller: widget.passwordController,
                    label: 'Password',
                    hint: 'Create a strong password',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (value.length < AppConstants.minPasswordLength) {
                        return 'Too short';
                      }
                      if (!AppConstants.strongPasswordRegex.hasMatch(value)) {
                        return 'Password too weak';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Password strength indicator
                  PasswordStrengthIndicator(
                    password: value.text,
                    showRequirements: true,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          AnimatedTextField(
            controller: widget.confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _nextStep(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              if (value != widget.passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        // Back button
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.isLoading ? null : _previousStep,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),

        // Next/Submit button
        Expanded(
          flex: _currentStep > 0 ? 1 : 1,
          child: ElevatedButton(
            onPressed: widget.isLoading 
                ? null 
                : (_currentStep == 1 && !_canProceedFromBasicInfo) 
                    ? null 
                    : _nextStep,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentStep < _totalSteps - 1
                            ? 'Continue'
                            : 'Create Account',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _currentStep < _totalSteps - 1
                            ? Icons.arrow_forward_rounded
                            : Icons.check_rounded,
                        size: 20,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
