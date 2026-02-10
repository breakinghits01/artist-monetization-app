import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Icon(
            Icons.cloud_upload_outlined,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Upload Your Music',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Share your creativity with the world',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          FilePickerWidget(
            onFilePicked: (path) {
              ref.read(uploadProvider.notifier).initiateUpload(path);
            },
          ),
          const SizedBox(height: 32),
          _buildGuidelines(theme),
          const SizedBox(height: 32),
          _buildStorageInfo(theme),
        ],
      ),
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
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPublishedView(BuildContext context, ThemeData theme, song) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 80,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Song Published!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your music is now live and ready to be discovered',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: () {
                // Navigate to profile to see the song
                // Note: Dashboard handles navigation
              },
              icon: const Icon(Icons.library_music),
              label: const Text('View in Profile'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                // Reset and upload another
                context.findAncestorStateOfType<ConsumerState>()?.ref
                    .read(uploadProvider.notifier)
                    .reset();
              },
              icon: const Icon(Icons.add),
              label: const Text('Upload Another'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    String message,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 80,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Upload Failed',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: () {
                ref.read(uploadProvider.notifier).reset();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelines(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Upload Guidelines',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildGuidelineItem(
              theme,
              Icons.check_circle_outline,
              'Supported formats: MP3, M4A, WAV, FLAC, OGG, AAC',
            ),
            _buildGuidelineItem(
              theme,
              Icons.check_circle_outline,
              'Maximum file size: 100MB',
            ),
            _buildGuidelineItem(
              theme,
              Icons.check_circle_outline,
              'Minimum file size: 100KB',
            ),
            _buildGuidelineItem(
              theme,
              Icons.check_circle_outline,
              'High-quality audio recommended (128kbps or higher)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineItem(ThemeData theme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageInfo(ThemeData theme) {
    return Card(
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upload Quota',
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  '10 songs max',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Storage Limit',
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  '1GB',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
