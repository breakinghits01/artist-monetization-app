import 'package:flutter/material.dart';
import '../services/download_service.dart';

class FormatSelectionDialog extends StatelessWidget {
  final String songId;
  final String songTitle;
  final List<DownloadFormat> formats;

  const FormatSelectionDialog({
    Key? key,
    required this.songId,
    required this.songTitle,
    required this.formats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Download Format'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              songTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...formats.map((format) => _FormatTile(
              format: format,
              onTap: () => Navigator.of(context).pop(format),
            )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _FormatTile extends StatelessWidget {
  final DownloadFormat format;
  final VoidCallback onTap;

  const _FormatTile({
    Key? key,
    required this.format,
    required this.onTap,
  }) : super(key: key);

  IconData _getFormatIcon(String format) {
    switch (format.toLowerCase()) {
      case 'mp3':
        return Icons.music_note;
      case 'wav':
      case 'flac':
        return Icons.high_quality;
      case 'ogg':
      case 'm4a':
      case 'aac':
        return Icons.audiotrack;
      default:
        return Icons.audio_file;
    }
  }

  Color _getFormatColor(String format) {
    switch (format.toLowerCase()) {
      case 'mp3':
        return Colors.blue;
      case 'wav':
      case 'flac':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getFormatColor(format.format);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFormatIcon(format.format),
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          format.format.toUpperCase(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            format.bitrate != null ? '${format.bitrate}kbps' : 'Lossless',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      format.quality,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.file_download,
                          size: 16,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          format.fileSizeFormatted,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
