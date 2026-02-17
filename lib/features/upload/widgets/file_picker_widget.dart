import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/file_picker_factory.dart';
import '../services/file_picker_service.dart';

class FilePickerWidget extends StatelessWidget {
  final Function(FilePickResult) onFilePicked;

  const FilePickerWidget({
    super.key,
    required this.onFilePicked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _pickFile(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.primary,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
        ),
        child: Column(
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Select Audio File',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to browse your files',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile(BuildContext context) async {
    try {
      debugPrint('Creating file picker service...');
      final picker = createFilePickerService();
      
      debugPrint('Requesting file selection...');
      final result = await picker.pickAudioFile();
      
      debugPrint('File picker completed, result: ${result != null}');
      
      if (!context.mounted) return;

      if (result != null) {
        debugPrint('File selected - Name: ${result.name}, Path: ${result.path}, Size: ${result.size}');
        
        if (result.path.isNotEmpty) {
          onFilePicked(result); // Pass the full result with bytes
        } else {
          _showError(context, 'Unable to access file');
        }
      } else {
        debugPrint('No file selected');
      }
    } catch (e, stackTrace) {
      debugPrint('Error in _pickFile: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!context.mounted) return;
      _showError(context, 'Error selecting file: ${e.toString()}');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
