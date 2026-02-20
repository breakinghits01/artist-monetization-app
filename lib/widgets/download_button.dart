import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/download_service.dart';
import '../services/providers/download_provider.dart';
import 'format_selection_dialog.dart';

class DownloadButton extends ConsumerStatefulWidget {
  final String songId;
  final String songTitle;
  final bool isIconButton;
  final Color? iconColor;

  const DownloadButton({
    Key? key,
    required this.songId,
    required this.songTitle,
    this.isIconButton = true,
    this.iconColor,
  }) : super(key: key);

  @override
  ConsumerState<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends ConsumerState<DownloadButton> {
  bool _isLoading = false;

  Future<void> _handleDownload(BuildContext context) async {
    setState(() => _isLoading = true);

    try {
      final downloadService = ref.read(downloadServiceProvider);

      // Get available formats
      final formats = await downloadService.getAvailableFormats(widget.songId);

      if (!mounted) return;

      if (formats.isEmpty) {
        _showError(context, 'Download not available for this song');
        return;
      }

      // Show format selection dialog
      final selectedFormat = await showDialog<DownloadFormat>(
        context: context,
        builder: (context) => FormatSelectionDialog(
          songId: widget.songId,
          songTitle: widget.songTitle,
          formats: formats,
        ),
      );

      if (selectedFormat == null || !mounted) return;

      // Start download with progress dialog
      _showDownloadProgress(context, selectedFormat);
    } catch (e) {
      if (mounted) {
        _showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDownloadProgress(BuildContext context, DownloadFormat format) {
    final downloadService = ref.read(downloadServiceProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DownloadProgressDialog(
        songId: widget.songId,
        songTitle: widget.songTitle,
        format: format,
        downloadService: downloadService,
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.isIconButton
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            );
    }

    if (widget.isIconButton) {
      return IconButton(
        icon: Icon(Icons.download, color: widget.iconColor),
        onPressed: () => _handleDownload(context),
        tooltip: 'Download',
      );
    } else {
      return ElevatedButton.icon(
        onPressed: () => _handleDownload(context),
        icon: const Icon(Icons.download),
        label: const Text('Download'),
      );
    }
  }
}

class _DownloadProgressDialog extends StatefulWidget {
  final String songId;
  final String songTitle;
  final DownloadFormat format;
  final DownloadService downloadService;

  const _DownloadProgressDialog({
    Key? key,
    required this.songId,
    required this.songTitle,
    required this.format,
    required this.downloadService,
  }) : super(key: key);

  @override
  State<_DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  double _progress = 0.0;
  bool _isDownloading = true;
  String? _errorMessage;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      final filePath = await widget.downloadService.downloadSong(
        songId: widget.songId,
        songTitle: widget.songTitle,
        format: widget.format.format,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _progress = progress);
          }
        },
      );

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _filePath = filePath;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _cancelDownload() {
    widget.downloadService.cancelDownload(widget.songId);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isDownloading ? 'Downloading...' : 
                  _errorMessage != null ? 'Download Failed' : 'Download Complete'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isDownloading) ...[
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 16),
            Text('${(_progress * 100).toStringAsFixed(0)}%'),
            const SizedBox(height: 8),
            Text(
              widget.songTitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            Text(
              '${widget.format.format.toUpperCase()} • ${widget.format.fileSizeFormatted}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else if (_errorMessage != null) ...[
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
          ] else ...[
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            const Text('Download completed successfully!'),
            if (_filePath != null) ...[
              const SizedBox(height: 8),
              Text(
                'Saved to: $_filePath',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ],
      ),
      actions: [
        if (_isDownloading)
          TextButton(
            onPressed: _cancelDownload,
            child: const Text('Cancel'),
          )
        else
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
      ],
    );
  }
}
