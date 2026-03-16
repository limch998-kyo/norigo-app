import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';

class ShareButtons extends StatefulWidget {
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

  @override
  State<ShareButtons> createState() => _ShareButtonsState();
}

class _ShareButtonsState extends State<ShareButtons> {
  bool _copied = false;

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: widget.url));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _shareTwitter() async {
    final encoded = Uri.encodeComponent('${widget.text}\n${widget.url}');
    try {
      await launchUrl(Uri.parse('https://twitter.com/intent/tweet?text=$encoded'), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _shareLine() async {
    final encoded = Uri.encodeComponent('${widget.text}\n${widget.url}');
    try {
      await launchUrl(Uri.parse('https://social-plugins.line.me/lineit/share?url=$encoded'), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _shareKakao() async {
    final encoded = Uri.encodeComponent('${widget.text}\n${widget.url}');
    try {
      await launchUrl(Uri.parse('https://story.kakao.com/share?url=$encoded'), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final shareLabel = widget.locale == 'ja' ? '友達に共有する' : widget.locale == 'ko' ? '친구에게 공유하기' : 'Share with friends';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(shareLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            // LINE (ja) / KakaoTalk (ko) — large primary button
            if (widget.locale == 'ja')
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _shareLine,
                    icon: const Icon(Icons.chat_bubble, size: 18),
                    label: const Text('LINEで共有', style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06C755),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
            if (widget.locale == 'ko')
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _shareKakao,
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text('카카오톡으로 공유', style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE500),
                      foregroundColor: const Color(0xFF191919),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),

            if (widget.locale == 'ja' || widget.locale == 'ko')
              const SizedBox(width: 8),

            // X button
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _shareTwitter,
                icon: const Text('𝕏', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                label: const Text('X'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Copy button (icon only)
            SizedBox(
              height: 44,
              width: 44,
              child: OutlinedButton(
                onPressed: _copyLink,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.zero,
                ),
                child: Icon(_copied ? Icons.check : Icons.content_copy, size: 18),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
