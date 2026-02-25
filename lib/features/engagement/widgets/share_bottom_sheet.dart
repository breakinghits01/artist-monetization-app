import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../player/models/song_model.dart';
import '../providers/share_provider.dart';

class ShareBottomSheet extends ConsumerWidget {
  final SongModel song;

  const ShareBottomSheet({super.key, required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final songUrl = 'https://artistmonetization.xyz/song/${song.id}';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.share_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share Song',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          song.title,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Share options
            ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _ShareOption(
                  icon: Icons.link,
                  iconColor: Colors.blue,
                  title: 'Copy Link',
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: songUrl));
                    await ref.read(shareProvider.notifier).trackShare(song.id, 'link');
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Link copied to clipboard'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                _ShareOption(
                  icon: Icons.chat_bubble,
                  iconColor: const Color(0xFF25D366),
                  title: 'WhatsApp',
                  onTap: () async {
                    final text = 'Check out "${song.title}" by ${song.artist} on Artist Monetization: $songUrl';
                    await Share.share(text);
                    await ref.read(shareProvider.notifier).trackShare(song.id, 'whatsapp');
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                _ShareOption(
                  icon: Icons.facebook,
                  iconColor: const Color(0xFF1877F2),
                  title: 'Facebook',
                  onTap: () async {
                    final text = 'Check out "${song.title}" by ${song.artist}: $songUrl';
                    await Share.share(text);
                    await ref.read(shareProvider.notifier).trackShare(song.id, 'facebook');
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                _ShareOption(
                  icon: Icons.telegram,
                  iconColor: const Color(0xFF0088CC),
                  title: 'Telegram',
                  onTap: () async {
                    final text = 'Check out "${song.title}" by ${song.artist}: $songUrl';
                    await Share.share(text);
                    await ref.read(shareProvider.notifier).trackShare(song.id, 'telegram');
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                _ShareOption(
                  icon: Icons.more_horiz,
                  iconColor: theme.colorScheme.primary,
                  title: 'More Options',
                  onTap: () async {
                    final text = 'Check out "${song.title}" by ${song.artist} on Artist Monetization: $songUrl';
                    await Share.share(text);
                    await ref.read(shareProvider.notifier).trackShare(song.id, 'other');
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: theme.colorScheme.onSurface.withOpacity(0.3),
      ),
      onTap: onTap,
    );
  }
}
