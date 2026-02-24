import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/responsive.dart';
import '../providers/upload_provider.dart';
import '../widgets/file_picker_widget.dart';
import '../widgets/upload_progress_widget.dart';
import '../widgets/metadata_form_widget.dart';

class UploadScreen extends ConsumerWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(uploadProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: uploadState.when(
          idle: () => _buildIdleView(context, ref, theme),
          validating: (fileName) => _buildValidatingView(theme, fileName),
          uploading: (session) => UploadProgressWidget(session: session),
          processing: (session) => UploadProgressWidget(session: session, isProcessing: true),
          completed: (session) => MetadataFormWidget(session: session),
          published: (song) => _buildPublishedView(context, theme, song),
          error: (message, session) => _buildErrorView(context, ref, theme, message),
        ),
      ),
    );
  }

  Widget _buildIdleView(BuildContext context, WidgetRef ref, ThemeData theme) {
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = !isDesktop;
    
    if (isMobile) {
      // Clean mobile layout - minimal scrolling
      return Column(
        children: [
          // Compact header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.08),
                  theme.colorScheme.secondary.withValues(alpha: 0.08),
                ],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.cloud_upload_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upload Your Music',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Share your creativity worldwide',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Compact stats
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactStat(theme, Icons.music_note_rounded, '10 songs'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCompactStat(theme, Icons.storage_rounded, '1GB total'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCompactStat(theme, Icons.file_present_rounded, '100MB'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // File picker section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  FilePickerWidget(
                    onFilePicked: (result) {
                      ref.read(uploadProvider.notifier).initiateUpload(result);
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Compact format chips
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: theme.colorScheme.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Supported Formats',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildMinimalChip(theme, 'MP3'),
                            _buildMinimalChip(theme, 'M4A'),
                            _buildMinimalChip(theme, 'WAV'),
                            _buildMinimalChip(theme, 'FLAC'),
                            _buildMinimalChip(theme, 'OGG'),
                            _buildMinimalChip(theme, 'AAC'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    
    // Desktop layout
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 40 : 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 800 : double.infinity),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Hero Section with gradient
              Container(
                padding: EdgeInsets.all(isDesktop ? 48 : 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.1),
                      theme.colorScheme.secondary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Gradient icon container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.cloud_upload_rounded,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Upload Your Music',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isDesktop ? 36 : 28,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Share your creativity with thousands of listeners worldwide',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: isDesktop ? 18 : 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Stats row
              if (isDesktop)
                Row(
                  children: [
                    Expanded(child: _buildStatCard(theme, Icons.music_note_rounded, '10 songs', 'Upload Quota')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard(theme, Icons.storage_rounded, '1GB total', 'Storage Limit')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard(theme, Icons.file_present_rounded, '100MB max', 'Per File')),
                  ],
                )
              else
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildStatCard(theme, Icons.music_note_rounded, '10 songs', 'Upload Quota')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard(theme, Icons.storage_rounded, '1GB total', 'Storage Limit')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(theme, Icons.file_present_rounded, '100MB max', 'Per File Size'),
                  ],
                ),
              
              const SizedBox(height: 40),
              
              // File picker
              FilePickerWidget(
                onFilePicked: (result) {
                  ref.read(uploadProvider.notifier).initiateUpload(result);
                },
              ),
              
              const SizedBox(height: 40),
              
              // Modern guidelines with chips
              _buildModernGuidelines(theme, isDesktop),
              
              const SizedBox(height: 32),
              
              // Benefits section
              _buildBenefitsSection(theme, isDesktop),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatCard(ThemeData theme, IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildModernGuidelines(ThemeData theme, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Supported Formats',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildFormatChip(theme, Icons.audiotrack_rounded, 'MP3'),
              _buildFormatChip(theme, Icons.library_music_rounded, 'M4A'),
              _buildFormatChip(theme, Icons.music_note_rounded, 'WAV'),
              _buildFormatChip(theme, Icons.album_rounded, 'FLAC'),
              _buildFormatChip(theme, Icons.speaker_rounded, 'OGG'),
              _buildFormatChip(theme, Icons.headphones_rounded, 'AAC'),
            ],
          ),
          const SizedBox(height: 24),
          _buildRequirement(theme, 'High-quality audio recommended (320kbps or higher)'),
          const SizedBox(height: 12),
          _buildRequirement(theme, 'Include proper metadata for better discovery'),
          const SizedBox(height: 12),
          _buildRequirement(theme, 'Original content only - respect copyright'),
        ],
      ),
    );
  }
  
  Widget _buildFormatChip(ThemeData theme, IconData icon, String format) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            format,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.check_circle, size: 16, color: theme.colorScheme.primary),
        ],
      ),
    );
  }
  
  Widget _buildRequirement(ThemeData theme, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline_rounded,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildBenefitsSection(ThemeData theme, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.3),
            theme.colorScheme.secondaryContainer.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why Upload Here?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (isDesktop)
            Row(
              children: [
                Expanded(child: _buildBenefitItem(theme, Icons.monetization_on_rounded, 'Earn Money', 'Get paid for every stream and download')),
                const SizedBox(width: 16),
                Expanded(child: _buildBenefitItem(theme, Icons.trending_up_rounded, 'Grow Audience', 'Reach thousands of active listeners')),
              ],
            )
          else
            Column(
              children: [
                _buildBenefitItem(theme, Icons.monetization_on_rounded, 'Earn Money', 'Get paid for every stream and download'),
                const SizedBox(height: 16),
                _buildBenefitItem(theme, Icons.trending_up_rounded, 'Grow Audience', 'Reach thousands of active listeners'),
              ],
            ),
          const SizedBox(height: 16),
          if (isDesktop)
            Row(
              children: [
                Expanded(child: _buildBenefitItem(theme, Icons.analytics_rounded, 'Track Analytics', 'Monitor your performance in real-time')),
                const SizedBox(width: 16),
                Expanded(child: _buildBenefitItem(theme, Icons.verified_rounded, 'Own Your Rights', 'You retain 100% ownership of your music')),
              ],
            )
          else
            Column(
              children: [
                _buildBenefitItem(theme, Icons.analytics_rounded, 'Track Analytics', 'Monitor your performance in real-time'),
                const SizedBox(height: 16),
                _buildBenefitItem(theme, Icons.verified_rounded, 'Own Your Rights', 'You retain 100% ownership of your music'),
              ],
            ),
        ],
      ),
    );
  }
  
  Widget _buildBenefitItem(ThemeData theme, IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
            ),
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
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildValidatingView(ThemeData theme, String fileName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Validating File...',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            fileName,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPublishedView(BuildContext context, ThemeData theme, song) {
    final isDesktop = Responsive.isDesktop(context);
    
    return Consumer(
      builder: (context, ref, child) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 40 : 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 600 : double.infinity),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gradient success animation
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.2),
                      theme.colorScheme.secondary.withOpacity(0.2),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Song Published!',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isDesktop ? 36 : 28,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your music is now live and ready to be discovered by thousands of listeners',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: isDesktop ? 18 : 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    // Reset upload state first
                    ref.read(uploadProvider.notifier).reset();
                    // Navigate to profile to see the uploaded song
                    context.go('/profile');
                  },
                  icon: const Icon(Icons.library_music_rounded),
                  label: const Text('View in Profile'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Reset and upload another
                    ref.read(uploadProvider.notifier).reset();
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Upload Another'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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

  Widget _buildErrorView(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    String message,
  ) {
    final isDesktop = Responsive.isDesktop(context);
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 40 : 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 600 : double.infinity),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 80,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Upload Failed',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                  fontSize: isDesktop ? 36 : 28,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  message,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    ref.read(uploadProvider.notifier).reset();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Compact mobile stat widget
  Widget _buildCompactStat(ThemeData theme, IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Minimal chip for format types
  Widget _buildMinimalChip(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
