import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/providers/download_provider.dart';
import '../services/download_service.dart';

/// Screen that shows active downloads with real-time progress
class DownloadManagerScreen extends ConsumerWidget {
  const DownloadManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeDownloadsAsync = ref.watch(downloadProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Downloads'),
        backgroundColor: const Color(0xFF0A0E27),
      ),
      backgroundColor: const Color(0xFF0A0E27),
      body: activeDownloadsAsync.when(
        data: (activeDownloads) {
          if (activeDownloads.isEmpty) {
            return _buildEmptyState(context);
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeDownloads.length,
            itemBuilder: (context, index) {
              final songId = activeDownloads.keys.elementAt(index);
              final progress = activeDownloads[songId]!;
              return _DownloadProgressCard(
                songId: songId,
                progress: progress,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error', style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_done,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No active downloads',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Downloads will appear here when in progress',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadProgressCard extends ConsumerWidget {
  final String songId;
  final DownloadProgress progress;

  const _DownloadProgressCard({
    required this.songId,
    required this.progress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadService = ref.read(downloadServiceProvider);
    final theme = Theme.of(context);

    return Card(
      color: const Color(0xFF1A1F3A),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Song title and status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progress.songTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusText(progress),
                        style: TextStyle(
                          color: _getStatusColor(progress.status),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildActionButton(context, downloadService, progress),
              ],
            ),

            const SizedBox(height: 12),

            // Progress bar
            if (progress.status == 'downloading') ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress.progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  if (progress.fileSize != null && progress.downloadedBytes != null)
                    Text(
                      '${_formatBytes(progress.downloadedBytes!)} / ${_formatBytes(progress.fileSize!)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],

            // Error message
            if (progress.status == 'failed' && progress.error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        progress.error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStatusText(DownloadProgress progress) {
    switch (progress.status) {
      case 'downloading':
        return 'Downloading ${progress.format.toUpperCase()}...';
      case 'completed':
        return 'Download completed';
      case 'failed':
        return 'Download failed';
      case 'cancelled':
        return 'Download cancelled';
      default:
        return progress.status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'downloading':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.orange;
      default:
        return Colors.white.withOpacity(0.7);
    }
  }

  Widget _buildActionButton(
    BuildContext context,
    DownloadService downloadService,
    DownloadProgress progress,
  ) {
    if (progress.status == 'downloading') {
      return IconButton(
        icon: const Icon(Icons.close, color: Colors.red),
        onPressed: () {
          downloadService.cancelDownload(songId);
        },
        tooltip: 'Cancel',
      );
    } else if (progress.status == 'failed') {
      return IconButton(
        icon: const Icon(Icons.refresh, color: Colors.blue),
        onPressed: () {
          // TODO: Retry download
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Retry functionality coming soon'),
            ),
          );
        },
        tooltip: 'Retry',
      );
    }
    return const SizedBox.shrink();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
