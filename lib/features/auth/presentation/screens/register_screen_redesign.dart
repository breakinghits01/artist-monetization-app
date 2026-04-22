import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../../providers/auth_provider.dart';
import '../widgets/register_form_steps.dart';

/// Modern redesigned registration screen with multi-step form
/// 
/// Features:
/// - Responsive split-screen layout (web)
/// - Multi-step progressive disclosure
/// - Enhanced input fields with animations
/// - Password strength indicator
/// - Interactive role selection
/// - Smooth page transitions
class RegisterScreenRedesign extends ConsumerStatefulWidget {
  const RegisterScreenRedesign({super.key});

  @override
  ConsumerState<RegisterScreenRedesign> createState() =>
      _RegisterScreenRedesignState();
}

class _RegisterScreenRedesignState
    extends ConsumerState<RegisterScreenRedesign> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final ValueNotifier<String> _selectedRole = ValueNotifier<String>('fan');
  final ValueNotifier<bool> _isRegistering = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _selectedRole.dispose();
    _isRegistering.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_isRegistering.value) {
      return;
    }

    _isRegistering.value = true;
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(authProvider.notifier).register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole.value,
      );

      messenger.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '✅ Registration successful! Redirecting to login...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF00E676),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) {
        _isRegistering.value = false;
        return;
      }

      _isRegistering.value = false;
      context.go(AppConstants.loginRoute);
    } on ApiException catch (e) {
      _isRegistering.value = false;

      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  e.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      _isRegistering.value = false;

      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Registration failed: ${e.toString()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = kIsWeb && screenWidth > 900;

    return Scaffold(
      // Explicitly enable body resize when soft keyboard appears.
      // Flutter default is true, but being explicit documents intent and
      // ensures future refactors don't accidentally disable it.
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: isWebLayout ? _buildWebLayout() : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildWebLayout() {
    return Row(
      children: [
        // Left side - Branding panel
        Expanded(
          flex: 5,
          child: _buildBrandingPanel(),
        ),

        // Right side - Form panel
        Expanded(
          flex: 7,
          child: _buildFormPanel(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Header with back button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.go(AppConstants.loginRoute),
                tooltip: 'Back to login',
              ),
              const Spacer(),
              _buildLoginLink(),
            ],
          ),
        ),

        // Form content.
        // On native Android/iOS, resizeToAvoidBottomInset on the Scaffold
        // already shrinks the body when the keyboard appears — no extra
        // padding is needed here (adding it would double-shrink and cause
        // RenderFlex overflow).
        // On web the Scaffold body does NOT resize for virtual keyboards,
        // so we manually push the form up with AnimatedPadding.
        Expanded(
          child: kIsWeb
              ? AnimatedPadding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  child: _buildFormPanel(),
                )
              : _buildFormPanel(),
        ),
      ],
    );
  }

  Widget _buildBrandingPanel() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              // App name
              Text(
                AppConstants.appName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Tagline
              Text(
                'Monetize Your Music & Connect with Fans',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 48),

              // Features
              _buildFeatureItem(
                icon: Icons.upload_rounded,
                title: 'Share Your Music',
                description: 'Upload and distribute your tracks',
              ),
              const SizedBox(height: 20),
              _buildFeatureItem(
                icon: Icons.monetization_on_rounded,
                title: 'Earn Revenue',
                description: 'Multiple monetization streams',
              ),
              const SizedBox(height: 20),
              _buildFeatureItem(
                icon: Icons.people_rounded,
                title: 'Build Fanbase',
                description: 'Connect directly with fans',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormPanel() {
    final isWebLayout = kIsWeb && MediaQuery.of(context).size.width > 900;
    // Reduced horizontal/vertical padding on mobile so form fields have
    // more room and the layout stays comfortable on small screens.
    // Desktop keeps the original 32px for the split-screen aesthetic.
    final padding = isWebLayout
        ? const EdgeInsets.all(32)
        : const EdgeInsets.symmetric(horizontal: 20, vertical: 12);

    return Container(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Create Account',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join the community and start your journey',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 32),

              // Multi-step form
              Expanded(
                child: ValueListenableBuilder<bool>(
                  valueListenable: _isRegistering,
                  builder: (context, isRegistering, child) {
                    return RegisterFormSteps(
                      formKey: _formKey,
                      usernameController: _usernameController,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                      selectedRole: _selectedRole,
                      onSubmit: _handleRegister,
                      isLoading: isRegistering,
                    );
                  },
                ),
              ),

              // Login link
              const SizedBox(height: 16),
              _buildLoginLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () => context.go(AppConstants.loginRoute),
          child: const Text(
            'Login',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
