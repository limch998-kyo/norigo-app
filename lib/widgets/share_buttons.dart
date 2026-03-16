import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';

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

  Future<void> _shareKakao() async {
    // KakaoTalk share via URL scheme
    final encoded = Uri.encodeComponent('$text\n$url');
    final uri = Uri.parse('https://story.kakao.com/share?url=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          locale == 'ja'
              ? '結果をシェア'
              : locale == 'ko'
                  ? '결과 공유하기'
                  : 'Share Results',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.mutedForeground,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Copy link (all locales)
            _ShareButton(
              icon: Icons.link,
              label: locale == 'ja' ? 'コピー' : locale == 'ko' ? '복사' : 'Copy',
              onTap: () => _copyLink(context),
            ),
            const SizedBox(width: 10),

            // Twitter/X (all locales)
            _ShareButton(
              icon: Icons.alternate_email,
              label: 'X',
              onTap: _shareTwitter,
            ),
            const SizedBox(width: 10),

            // LINE (ja only)
            if (locale == 'ja')
              _ShareButton(
                icon: Icons.chat_bubble_outline,
                label: 'LINE',
                onTap: _shareLine,
                color: const Color(0xFF06C755), // LINE green
              ),

            // KakaoTalk (ko only)
            if (locale == 'ko')
              _ShareButton(
                icon: Icons.chat,
                label: '카카오톡',
                onTap: _shareKakao,
                color: const Color(0xFFFEE500), // Kakao yellow
                textColor: Colors.black,
              ),
          ],
        ),
      ],
    );
  }
}

class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Color? textColor;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = textColor ?? AppTheme.foreground;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color ?? AppTheme.border),
          color: color?.withValues(alpha: 0.1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color ?? fgColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
