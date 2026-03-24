import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../player/models/song_model.dart';
import '../../providers/user_songs_provider.dart';
import '../../../discover/providers/song_provider.dart';

/// Editable song information dialog
/// Allows song owner to update title, genre, description, price, and exclusive status
class EditSongDialog extends ConsumerStatefulWidget {
  final SongModel song;

  const EditSongDialog({
    super.key,
    required this.song,
  });

  @override
  ConsumerState<EditSongDialog> createState() => _EditSongDialogState();
}

class _EditSongDialogState extends ConsumerState<EditSongDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late String _selectedGenre;
  late bool _isExclusive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song.title);
    _descriptionController = TextEditingController(text: '');
    _priceController = TextEditingController(text: widget.song.tokenReward.toString());
    _selectedGenre = widget.song.genre ?? 'Pop';
    _isExclusive = widget.song.isPremium;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updates = {
        'title': _titleController.text.trim(),
        'genre': _selectedGenre,
        'description': _descriptionController.text.trim(),
        'price': int.parse(_priceController.text),
        'exclusive': _isExclusive,
      };

      await ref.read(userSongsProvider.notifier).updateSong(widget.song.id, updates);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Song Updated',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Changes saved successfully',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.toString().replaceFirst('Exception: ', ''),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final genresAsync = ref.watch(genresProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1D2E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    const Color(0xFF9C27B0),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Song',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Update song information',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      TextFormField(
                        controller: _titleController,
                        enabled: !_isSaving,
                        decoration: InputDecoration(
                          labelText: 'Song Title *',
                          hintText: 'Enter song title',
                          prefixIcon: const Icon(Icons.music_note),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.withValues(alpha: 0.1),
                        ),
                        maxLength: 100,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          if (value.trim().length < 2) {
                            return 'Title must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Genre
                      genresAsync.when(
                        data: (genres) => DropdownButtonFormField<String>(
                          value: genres.contains(_selectedGenre) ? _selectedGenre : genres.first,
                          decoration: InputDecoration(
                            labelText: 'Genre *',
                            prefixIcon: const Icon(Icons.category),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey.withValues(alpha: 0.1),
                          ),
                          isExpanded: true,
                          items: genres.map((genre) {
                            return DropdownMenuItem(
                              value: genre,
                              child: Text(genre),
                            );
                          }).toList(),
                          onChanged: _isSaving
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedGenre = value!;
                                  });
                                },
                        ),
                        loading: () => DropdownButtonFormField<String>(
                          value: _selectedGenre,
                          decoration: InputDecoration(
                            labelText: 'Genre *',
                            prefixIcon: const Icon(Icons.category),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: [_selectedGenre].map((genre) {
                            return DropdownMenuItem(
                              value: genre,
                              child: Text(genre),
                            );
                          }).toList(),
                          onChanged: null,
                        ),
                        error: (error, stack) => TextFormField(
                          initialValue: _selectedGenre,
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: 'Genre',
                            errorText: 'Failed to load genres',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        enabled: !_isSaving,
                        decoration: InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'Add a description for your song',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.withValues(alpha: 0.1),
                        ),
                        maxLines: 3,
                        maxLength: 500,
                      ),
                      const SizedBox(height: 16),
                      // Price
                      TextFormField(
                        controller: _priceController,
                        enabled: !_isSaving,
                        decoration: InputDecoration(
                          labelText: 'Token Reward *',
                          hintText: '5-100',
                          prefixIcon: const Icon(Icons.monetization_on),
                          suffixText: 'tokens',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.withValues(alpha: 0.1),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Token reward is required';
                          }
                          final price = int.tryParse(value);
                          if (price == null) {
                            return 'Must be a valid number';
                          }
                          if (price < 5 || price > 100) {
                            return 'Must be between 5 and 100';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Exclusive Toggle
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isExclusive
                              ? const Color(0xFFFFD700).withValues(alpha: 0.1)
                              : const Color(0xFF4CAF50).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isExclusive
                                ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                                : const Color(0xFF4CAF50).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isExclusive ? Icons.lock : Icons.lock_open,
                              color: _isExclusive
                                  ? const Color(0xFFFFD700)
                                  : const Color(0xFF4CAF50),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isExclusive ? 'Exclusive Content' : 'Public Access',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: _isExclusive
                                          ? const Color(0xFFFFD700)
                                          : const Color(0xFF4CAF50),
                                    ),
                                  ),
                                  Text(
                                    _isExclusive
                                        ? 'Only premium users can access'
                                        : 'Everyone can listen to this song',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: (isDark ? Colors.white : Colors.black)
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isExclusive,
                              onChanged: _isSaving
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _isExclusive = value;
                                      });
                                    },
                              activeColor: const Color(0xFFFFD700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Action Buttons
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
