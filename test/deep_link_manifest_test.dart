import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:norigo_app/services/deep_link_parser.dart';

/// Keeps the Android App Links intent-filter and the deep link parser in
/// lockstep, in both directions:
///
///  1. Every path the manifest claims must resolve to a native in-app route.
///     A claimed-but-unroutable path is opened "externally" by the handler,
///     which on Android fires a VIEW intent that App Links resolves right
///     back into the app — an infinite bounce loop.
///  2. /api/* must never be claimed. Affiliate redirects (/api/out) have to
///     reach a real browser or the whole monetisation chain breaks.
///  3. Every shareable web URL shape (all web locales × all native routes)
///     must be claimed, so shared links actually open in-app.
///
/// The iOS AASA file (project_meetup/public/.well-known/
/// apple-app-site-association) mirrors the same path set; update both when
/// this changes.
void main() {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();

  final exactPaths = RegExp(r'android:path="([^"]+)"')
      .allMatches(manifest)
      .map((m) => m.group(1)!)
      .toList();
  final prefixPaths = RegExp(r'android:pathPrefix="([^"]+)"')
      .allMatches(manifest)
      .map((m) => m.group(1)!)
      .toList();

  /// Simulates Android intent-filter path matching for our filter: an
  /// android:path must match exactly, an android:pathPrefix by prefix.
  bool claimed(String path) =>
      exactPaths.contains(path) || prefixPaths.any(path.startsWith);

  // Mirrors src/i18n/routing.ts in project_meetup ('' = unprefixed).
  const localePrefixes = ['', '/ja', '/ko', '/en', '/zh', '/zh-TW', '/fr', '/ar'];

  test('manifest declares scoped App Links paths at all', () {
    expect(exactPaths, isNotEmpty,
        reason: 'expected android:path entries in the App Links filter');
    expect(prefixPaths, isNotEmpty,
        reason: 'expected android:pathPrefix entries in the App Links filter');
  });

  test('never claims /api/* — affiliate redirects must reach a browser', () {
    for (final locale in localePrefixes) {
      for (final api in ['/api/out', '/api/share', '/api/log', '/api/og']) {
        expect(claimed('$locale$api'), isFalse,
            reason: '$locale$api must not be claimed by the app');
      }
    }
    // The wrapped affiliate URL shape used by BookingProvider.
    expect(
      claimed('/api/out'),
      isFalse,
      reason: '/api/out is the affiliate redirect — claiming it would '
          'bounce booking clicks back into the app',
    );
  });

  test('every claimed path resolves to a native in-app route', () {
    // A pathPrefix claim covers concrete URLs underneath it; probe with a
    // representative tail. Exact paths are probed as-is.
    final probes = <String>[
      ...exactPaths,
      ...prefixPaths.map((p) => '${p}sample-slug'),
    ];
    for (final path in probes) {
      final target = parseNorigoUri(Uri.parse('https://norigo.app$path'));
      expect(target, isNotNull, reason: '$path did not parse as ours');
      expect(
        target!.kind,
        isNot(DeepLinkKind.external),
        reason: '$path is claimed by the manifest but the parser cannot '
            'render it natively — it would bounce-loop on Android',
      );
    }
  });

  test('claims every shareable web URL shape (all locales × all routes)', () {
    const shareableRoutes = [
      '/s/abc123',
      '/result',
      '/stay/result',
      '/guide/tokyo-first-time',
      '/spot/tokyo-tower',
      '/vote/WvIR-O18',
    ];
    for (final locale in localePrefixes) {
      for (final route in shareableRoutes) {
        final url = '$locale$route';
        expect(claimed(url), isTrue,
            reason: '$url is a shareable web URL but is not claimed — it '
                'would open in the browser instead of in-app');
        // And the parser must agree it is natively routable.
        final target = parseNorigoUri(Uri.parse('https://norigo.app$url'));
        expect(target!.kind, isNot(DeepLinkKind.external),
            reason: '$url should resolve to a native route');
      }
    }
  });
}
