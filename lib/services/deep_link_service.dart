import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/constants.dart';
import 'deep_link_parser.dart';

/// Receives incoming norigo links (cold-start + while running), resolves short
/// `/s/:id` links to their real destination, and emits typed [DeepLinkTarget]s.
///
/// The parsing itself lives in [parseNorigoUri] (pure + unit-tested); this class
/// only owns the platform plumbing and the one network call needed to expand a
/// short link.
class DeepLinkService {
  DeepLinkService({AppLinks? appLinks, Dio? dio})
      : _appLinks = appLinks ?? AppLinks(),
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConstants.apiBaseUrl,
              // A short link replies with a 307 redirect; we want the Location
              // header, not the redirected body.
              followRedirects: false,
              validateStatus: (s) => s != null && s < 400,
            ));

  final AppLinks _appLinks;
  final Dio _dio;
  StreamSubscription<Uri>? _sub;

  /// Begin listening. [onTarget] fires for the launch link (if any) and for
  /// every link received while the app is running. Short links are expanded
  /// before the callback sees them.
  Future<void> start(void Function(DeepLinkTarget target) onTarget) async {
    // Cold start: the link that launched the app, if any.
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        await _dispatch(initial, onTarget);
      }
    } catch (e) {
      debugPrint('DeepLinkService: getInitialLink failed: $e');
    }

    // Warm: links delivered while the app is already running.
    _sub = _appLinks.uriLinkStream.listen(
      (uri) => _dispatch(uri, onTarget),
      onError: (Object e) => debugPrint('DeepLinkService: link stream error: $e'),
    );
  }

  Future<void> _dispatch(
    Uri uri,
    void Function(DeepLinkTarget target) onTarget,
  ) async {
    final target = parseNorigoUri(uri);
    if (target == null) return; // Not one of ours.

    if (target.kind == DeepLinkKind.shortLink && target.id != null) {
      final resolved = await _resolveShortLink(target.id!);
      if (resolved != null) {
        onTarget(resolved);
      } else {
        // Couldn't expand it — hand back an external target so the handler can
        // open it in a browser rather than silently dropping it.
        onTarget(DeepLinkTarget.external(uri));
      }
      return;
    }

    onTarget(target);
  }

  /// Expand `/s/:id` by asking the web for its 307 redirect and re-parsing the
  /// `Location` it points at (e.g. `/stay/result?...`). Returns null on failure.
  Future<DeepLinkTarget?> _resolveShortLink(String id) async {
    try {
      final res = await _dio.get('/s/$id');
      final location = res.headers.value('location');
      if (location == null || location.isEmpty) return null;
      final resolvedUri = Uri.parse(location).hasScheme
          ? Uri.parse(location)
          : Uri.parse('${AppConstants.apiBaseUrl}$location');
      return parseNorigoUri(resolvedUri);
    } catch (e) {
      debugPrint('DeepLinkService: short link resolve failed for $id: $e');
      return null;
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
