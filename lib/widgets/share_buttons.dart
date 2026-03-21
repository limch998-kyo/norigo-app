import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import '../utils/tr.dart';

// Official LINE logo SVG path
const _lineLogoPath = 'M19.365 9.863c.349 0 .63.285.63.631 0 .345-.281.63-.63.63H17.61v1.125h1.755c.349 0 .63.283.63.63 0 .344-.281.629-.63.629h-2.386c-.345 0-.627-.285-.627-.629V8.108c0-.345.282-.63.63-.63h2.386c.346 0 .627.285.627.63 0 .349-.281.63-.63.63H17.61v1.125h1.755zm-3.855 3.016c0 .27-.174.51-.432.596-.064.021-.133.031-.199.031-.211 0-.391-.09-.51-.25l-2.443-3.317v2.94c0 .344-.279.629-.631.629-.346 0-.626-.285-.626-.629V8.108c0-.27.173-.51.43-.595.06-.023.136-.033.194-.033.195 0 .375.104.495.254l2.462 3.33V8.108c0-.345.282-.63.63-.63.345 0 .63.285.63.63v4.771zm-5.741 0c0 .344-.282.629-.631.629-.345 0-.627-.285-.627-.629V8.108c0-.345.282-.63.63-.63.346 0 .628.285.628.63v4.771zm-2.466.629H4.917c-.345 0-.63-.285-.63-.629V8.108c0-.345.285-.63.63-.63.348 0 .63.285.63.63v4.141h1.756c.348 0 .629.283.629.63 0 .344-.282.629-.629.629M24 10.314C24 4.943 18.615.572 12 .572S0 4.943 0 10.314c0 4.811 4.27 8.842 10.035 9.608.391.082.923.258 1.058.59.12.301.079.766.038 1.08l-.164 1.02c-.045.301-.24 1.186 1.049.645 1.291-.539 6.916-4.078 9.436-6.975C23.176 14.393 24 12.458 24 10.314';

// Official KakaoTalk logo SVG path
const _kakaoLogoPath = 'M12 3C6.477 3 2 6.463 2 10.691c0 2.72 1.8 5.108 4.516 6.449-.147.529-.946 3.405-.978 3.612 0 0-.02.166.088.229.108.063.235.014.235.014.31-.043 3.592-2.349 4.157-2.747.64.092 1.3.142 1.982.142 5.523 0 10-3.463 10-7.699C22 6.463 17.523 3 12 3';

class ShareButtons extends StatefulWidget {
  final String title;
  final String text;
  final String url;
  final String locale;

  const ShareButtons({super.key, required this.title, required this.text, required this.url, this.locale = 'en'});

  @override
  State<ShareButtons> createState() => _ShareButtonsState();
}

class _ShareButtonsState extends State<ShareButtons> {
  bool _copied = false;

  String _getShareUrl(String platform) {
    final uri = Uri.parse(widget.url);
    final params = Map<String, String>.from(uri.queryParameters);
    params['utm_source'] = 'share';
    params['utm_medium'] = platform;
    return uri.replace(queryParameters: params).toString();
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _getShareUrl('copy')));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _copied = false); });
  }

  Future<void> _nativeShare() async {
    await SharePlus.instance.share(
      ShareParams(text: '${widget.text}\n${_getShareUrl('native')}'),
    );
  }

  Future<void> _shareTwitter() async {
    // Match web: text and url as separate params
    final url = _getShareUrl('x');
    final text = Uri.encodeComponent(widget.text);
    final encodedUrl = Uri.encodeComponent(url);
    try {
      await launchUrl(
        Uri.parse('https://twitter.com/intent/tweet?text=$text&url=$encodedUrl'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }

  Future<void> _shareLine() async {
    // Match web: use LIFF shareTargetPicker for rich card sharing
    final shareUrl = _getShareUrl('line');
    // Add openExternalBrowser=1 like web does
    final urlWithExternal = shareUrl.contains('?')
        ? '$shareUrl&openExternalBrowser=1'
        : '$shareUrl?openExternalBrowser=1';

    final liffParams = Uri(queryParameters: {
      'url': urlWithExternal,
      'title': widget.title,
      'desc': widget.text,
    }).query;

    final liffUrl = 'https://liff.line.me/2009553286-JcRNsKER?$liffParams';

    try {
      await launchUrl(Uri.parse(liffUrl), mode: LaunchMode.externalApplication);
    } catch (_) {
      // Fallback: simple LINE share
      final encoded = Uri.encodeComponent('${widget.text}\n$shareUrl');
      await launchUrl(
        Uri.parse('https://line.me/R/share?text=$encoded'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _shareKakao() async {
    final shareUrl = _getShareUrl('kakao');
    final imageUrl = 'https://norigo.app/api/og?locale=${widget.locale}';

    // Use Kakao Flutter SDK — same as web's Kakao.Share.sendDefault()
    final template = FeedTemplate(
      content: Content(
        title: widget.title,
        description: widget.text,
        imageUrl: Uri.parse(imageUrl),
        link: Link(
          webUrl: Uri.parse(shareUrl),
          mobileWebUrl: Uri.parse(shareUrl),
        ),
      ),
      buttons: [
        Button(
          title: tr(widget.locale, ja: '結果を見る', ko: '결과 보기', en: 'View Results', zh: '查看结果'),
          link: Link(
            webUrl: Uri.parse(shareUrl),
            mobileWebUrl: Uri.parse(shareUrl),
          ),
        ),
      ],
    );

    try {
      // Check if KakaoTalk is installed
      if (await ShareClient.instance.isKakaoTalkSharingAvailable()) {
        final uri = await ShareClient.instance.shareDefault(template: template);
        await ShareClient.instance.launchKakaoTalk(uri);
      } else {
        // KakaoTalk not installed — use web share fallback
        final uri = await WebSharerClient.instance.makeDefaultUrl(template: template);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Final fallback: native share
      await SharePlus.instance.share(
        ShareParams(text: '${widget.text}\n$shareUrl'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shareLabel = tr(widget.locale, ja: '友達に共有する', ko: '친구에게 공유하기', en: 'Share with friends', zh: '分享给朋友');
    final viaLabel = tr(widget.locale, ja: 'で共有', ko: '로 공유', en: ' Share', zh: ' 分享');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(shareLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),

        // Primary messenger button — full width (matching web)
        if (widget.locale == 'ja')
          SizedBox(width: double.infinity, height: 44, child: ElevatedButton(
            onPressed: _shareLine,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06C755), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              CustomPaint(size: const Size(20, 20), painter: _SvgIconPainter(_lineLogoPath, Colors.white)),
              const SizedBox(width: 8),
              Text('LINE$viaLabel', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ]),
          )),

        if (widget.locale == 'ko')
          SizedBox(width: double.infinity, height: 44, child: ElevatedButton(
            onPressed: _shareKakao,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFEE500), foregroundColor: const Color(0xFF191919),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              CustomPaint(size: const Size(20, 20), painter: _SvgIconPainter(_kakaoLogoPath, const Color(0xFF191919))),
              const SizedBox(width: 8),
              Text('카카오톡$viaLabel', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ]),
          )),

        if (widget.locale != 'ja' && widget.locale != 'ko')
          SizedBox(width: double.infinity, height: 44, child: ElevatedButton.icon(
            onPressed: _nativeShare,
            icon: const Icon(Icons.share, size: 18),
            label: Text(shareLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          )),

        const SizedBox(height: 8),

        // Secondary buttons row (matching web: X + Copy)
        Row(children: [
          // X button
          Expanded(child: SizedBox(height: 40, child: OutlinedButton(
            onPressed: _shareTwitter,
            style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('𝕏', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(width: 6),
              Text('X', style: TextStyle(fontSize: 13)),
            ]),
          ))),
          const SizedBox(width: 8),

          // Copy / URL button
          Expanded(child: SizedBox(height: 40, child: OutlinedButton(
            onPressed: _copyLink,
            style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(_copied ? Icons.check : Icons.content_copy, size: 16),
              const SizedBox(width: 6),
              Text(_copied
                ? tr(widget.locale, ja: 'コピー済み', ko: '복사됨', en: 'Copied', zh: '已复制')
                : 'URL',
                style: const TextStyle(fontSize: 13)),
            ]),
          ))),
        ]),
      ],
    );
  }
}

/// Paints an SVG path icon (for LINE/KakaoTalk official logos)
class _SvgIconPainter extends CustomPainter {
  final String pathData;
  final Color color;

  _SvgIconPainter(this.pathData, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = _parseSvgPath(pathData);
    final bounds = path.getBounds();
    final scale = size.width / bounds.width.clamp(1, 100);

    canvas.save();
    canvas.scale(scale * 0.83);
    canvas.translate(-bounds.left + (size.width / scale - bounds.width) / 2, -bounds.top + (size.height / scale - bounds.height) / 2);
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  Path _parseSvgPath(String d) {
    final path = Path();
    final commands = RegExp(r'([MmLlHhVvCcSsQqTtAaZz])([^MmLlHhVvCcSsQqTtAaZz]*)').allMatches(d);

    double cx = 0, cy = 0;
    for (final match in commands) {
      final cmd = match.group(1)!;
      final args = RegExp(r'[-+]?[0-9]*\.?[0-9]+').allMatches(match.group(2) ?? '').map((m) => double.parse(m.group(0)!)).toList();

      switch (cmd) {
        case 'M': cx = args[0]; cy = args[1]; path.moveTo(cx, cy); break;
        case 'm': cx += args[0]; cy += args[1]; path.moveTo(cx, cy); break;
        case 'L': cx = args[0]; cy = args[1]; path.lineTo(cx, cy); break;
        case 'l': cx += args[0]; cy += args[1]; path.lineTo(cx, cy); break;
        case 'H': cx = args[0]; path.lineTo(cx, cy); break;
        case 'h': cx += args[0]; path.lineTo(cx, cy); break;
        case 'V': cy = args[0]; path.lineTo(cx, cy); break;
        case 'v': cy += args[0]; path.lineTo(cx, cy); break;
        case 'C':
          for (var i = 0; i + 5 < args.length; i += 6) {
            path.cubicTo(args[i], args[i+1], args[i+2], args[i+3], args[i+4], args[i+5]);
            cx = args[i+4]; cy = args[i+5];
          }
          break;
        case 'c':
          for (var i = 0; i + 5 < args.length; i += 6) {
            path.cubicTo(cx+args[i], cy+args[i+1], cx+args[i+2], cy+args[i+3], cx+args[i+4], cy+args[i+5]);
            cx += args[i+4]; cy += args[i+5];
          }
          break;
        case 'S':
          for (var i = 0; i + 3 < args.length; i += 4) {
            path.cubicTo(cx, cy, args[i], args[i+1], args[i+2], args[i+3]);
            cx = args[i+2]; cy = args[i+3];
          }
          break;
        case 'Z': case 'z': path.close(); break;
      }
    }
    return path;
  }
}
