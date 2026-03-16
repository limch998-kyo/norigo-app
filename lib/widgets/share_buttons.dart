import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareButtons extends StatelessWidget {
  final String title;
  final String text;
  final String url;
  final String locale;

  const ShareButtons({
    super.key,
    required this.title,
    required this.text,
    required this.url,
    this.locale = 'en',
  });

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            locale == 'ja'
                ? 'リンクをコピーしました'
                : locale == 'ko'
                    ? '링크가 복사되었습니다'
                    : 'Link copied!',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareTwitter() async {
    final encoded = Uri.encodeComponent('$text\n$url');
    final uri = Uri.parse('https://twitter.com/intent/tweet?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareLine() async {
    final encoded = Uri.encodeComponent('$text\n$url');
    final uri = Uri.parse('https://social-plugins.line.me/lineit/share?url=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Copy link
        _ShareButton(
          icon: Icons.link,
          label: locale == 'ja' ? 'コピー' : locale == 'ko' ? '복사' : 'Copy',
          onTap: () => _copyLink(context),
          theme: theme,
        ),
        const SizedBox(width: 12),

        // Twitter/X
        _ShareButton(
          icon: Icons.alternate_email,
          label: 'X',
          onTap: _shareTwitter,
          theme: theme,
        ),

        // LINE (ja only)
        if (locale == 'ja') ...[
          const SizedBox(width: 12),
          _ShareButton(
            icon: Icons.chat_bubble_outline,
            label: 'LINE',
            onTap: _shareLine,
            theme: theme,
          ),
        ],
      ],
    );
  }
}

class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ThemeData theme;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.onSurface),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
