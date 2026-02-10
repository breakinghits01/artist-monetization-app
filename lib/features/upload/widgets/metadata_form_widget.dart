import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/upload_session.dart';
import '../models/song_metadata.dart';
import '../providers/upload_provider.dart';

class MetadataFormWidget extends ConsumerStatefulWidget {
  final UploadSession session;

  const MetadataFormWidget({
    super.key,
    required this.session,
  });

  @override
  ConsumerState<MetadataFormWidget> createState() => _MetadataFormWidgetState();
}

class _MetadataFormWidgetState extends ConsumerState<MetadataFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController(text: '10');

  String? _selectedGenre;
  String? _coverArtPath;
  bool _exclusive = false;
  bool _allowDownload = false;
  bool _allowRemix = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill title from file name
    final fileName = widget.session.fileName;
    final titleWithoutExt = fileName.split('.').first;
    _titleController.text = titleWithoutExt.replaceAll('_', ' ').replaceAll('-', ' ');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // Header
            Text(
              'Song Details',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add information about your song',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),

            // Cover Art
            _buildCoverArtPicker(theme),
            const SizedBox(height: 24),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'Enter song title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.music_note),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                if (value.length > 100) {
                  return 'Title must be less than 100 characters';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Genre
            DropdownButtonFormField<String>(
              value: _selectedGenre,
              decoration: const InputDecoration(
                labelText: 'Genre',
                hintText: 'Select genre',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: MusicGenres.all.map((genre) {
                return DropdownMenuItem(
                  value: genre,
                  child: Text(genre),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedGenre = value);
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Tell listeners about your song',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              maxLength: 500,
              validator: (value) {
                if (value != null && value.length > 500) {
                  return 'Description must be less than 500 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Price
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price (Tokens) *',
                hintText: '10',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.token),
                helperText: 'Set your song price in tokens',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a price';
                }
                final price = int.tryParse(value);
                if (price == null || price < 0) {
                  return 'Please enter a valid price (0 or higher)';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Options
            _buildOptionSwitch(
              theme,
              'Exclusive Release',
              'Mark as exclusive content',
              _exclusive,
              (value) => setState(() => _exclusive = value),
            ),
            _buildOptionSwitch(
              theme,
              'Allow Downloads',
              'Let users download this song',
              _allowDownload,
              (value) => setState(() => _allowDownload = value),
            ),
            _buildOptionSwitch(
              theme,
              'Allow Remixes',
              'Allow others to remix your song',
              _allowRemix,
              (value) => setState(() => _allowRemix = value),
            ),
            const SizedBox(height: 32),

            // Submit buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : _saveDraft,
                    child: const Text('Save as Draft'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _publish,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.publish),
                    label: Text(_isSubmitting ? 'Publishing...' : 'Publish'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverArtPicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cover Art',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickCoverArt,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.5),
              ),
            ),
            child: _coverArtPath != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_coverArtPath!),
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          onPressed: () {
                            setState(() => _coverArtPath = null);
                          },
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 48,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add Cover Image',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionSwitch(
    ThemeData theme,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _pickCoverArt() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          setState(() => _coverArtPath = file.path);
        }
      }
    } catch (e) {
      _showError('Error selecting image: ${e.toString()}');
    }
  }

  Future<void> _saveDraft() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final metadata = SongMetadata(
        title: _titleController.text.trim(),
        genre: _selectedGenre,
        description: _descriptionController.text.trim(),
        price: int.parse(_priceController.text),
        coverArtPath: _coverArtPath,
        exclusive: _exclusive,
        allowDownload: _allowDownload,
        allowRemix: _allowRemix,
      );

      await ref.read(uploadProvider.notifier).saveDraft(
            widget.session,
            metadata,
          );

      if (mounted) {
        _showSnackBar('Draft saved successfully! Check your profile.', isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to save draft: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final metadata = SongMetadata(
        title: _titleController.text.trim(),
        genre: _selectedGenre,
        description: _descriptionController.text.trim(),
        price: int.parse(_priceController.text),
        coverArtPath: _coverArtPath,
        exclusive: _exclusive,
        allowDownload: _allowDownload,
        allowRemix: _allowRemix,
      );

      await ref.read(uploadProvider.notifier).submitMetadata(
            widget.session,
            metadata,
          );

      if (mounted) {
        _showSnackBar('Song published successfully!', isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to publish song: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showError(String message) {
    _showSnackBar(message, isError: true);
  }
}
