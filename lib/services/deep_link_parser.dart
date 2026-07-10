import 'dart:convert';

/// What kind of destination an incoming link resolves to.
enum DeepLinkKind {
  /// /stay/result — restore a stay (hotel-area) search.
  stay,

  /// /result — restore a meetup (centre-station) search.
  meetup,

  /// /guide/:slug — open a guide detail.
  guide,

  /// /spot/:slug — open an attraction detail.
  spot,

  /// /vote/:id — open a vote poll.
  vote,

  /// /s/:id — a short share URL that must be resolved server-side first.
  shortLink,

  /// A norigo link we recognise as ours but can't render natively yet
  /// (e.g. /station/:slug, /trip/itinerary, bare home). Open externally.
  external,
}

/// A single landmark carried in a stay deep link (`l` param JSON).
class DeepLinkLandmark {
  final String name;
  final double lat;
  final double lng;

  const DeepLinkLandmark({
    required this.name,
    required this.lat,
    required this.lng,
  });
}

/// A parsed, typed representation of an incoming norigo link. Produced purely
/// from a [Uri] with no I/O so it can be unit-tested exhaustively.
class DeepLinkTarget {
  final DeepLinkKind kind;

  /// guide / spot slug.
  final String? slug;

  /// vote poll id, or short-link id.
  final String? id;

  // Search restoration fields (stay + meetup).
  final String? region;
  final String? mode;
  final String? budget;
  final String? checkIn;
  final String? checkOut;
  final String? stayStyle;
  final String? category;
  final List<DeepLinkLandmark> landmarks;
  final List<String> stationIds;
  final List<String> options;

  /// The original link, kept for the [DeepLinkKind.external] fallback.
  final Uri uri;

  const DeepLinkTarget._({
    required this.kind,
    required this.uri,
    this.slug,
    this.id,
    this.region,
    this.mode,
    this.budget,
    this.checkIn,
    this.checkOut,
    this.stayStyle,
    this.category,
    this.landmarks = const [],
    this.stationIds = const [],
    this.options = const [],
  });

  /// A link to hand off to an external browser (unresolvable short link,
  /// not-yet-native route, etc.).
  factory DeepLinkTarget.external(Uri uri) =>
      DeepLinkTarget._(kind: DeepLinkKind.external, uri: uri);
}

/// Locale segments the web prefixes onto paths (e.g. /ja/stay/result), in the
/// web's canonical casing. Must mirror the web's locale list
/// (src/i18n/routing.ts in project_meetup); test/deep_link_manifest_test.dart
/// derives the manifest expectations from this set.
const localeSegments = {'ja', 'ko', 'en', 'zh', 'zh-TW', 'fr', 'ar'};

/// Matching is case-insensitive: for norigo:// links the first path segment
/// lands in the URI authority, which Dart lowercases (zh-TW → zh-tw).
final _localeSegmentsLower =
    localeSegments.map((l) => l.toLowerCase()).toSet();

/// Hosts we own. Shared with the app shell so the "open our own URLs in an
/// in-app browser view" rule can't drift from what the parser recognises.
const norigoHosts = {'norigo.app', 'www.norigo.app'};

/// Parse an incoming URI into a [DeepLinkTarget], or `null` if it isn't a
/// norigo link at all (so the caller can ignore it).
///
/// Accepts both `https://norigo.app/...` app links and the `norigo://` custom
/// scheme. Locale path prefixes are stripped. Unknown-but-ours paths resolve to
/// [DeepLinkKind.external] so the handler can open them in a browser rather than
/// dead-end.
DeepLinkTarget? parseNorigoUri(Uri uri) {
  final isNorigo = uri.scheme == 'norigo' ||
      ((uri.scheme == 'https' || uri.scheme == 'http') &&
          norigoHosts.contains(uri.host));
  if (!isNorigo) return null;

  final segments = _pathSegments(uri);
  if (segments.isEmpty) {
    // Bare norigo.app / norigo:// — nothing to route, just the home app.
    return DeepLinkTarget._(kind: DeepLinkKind.external, uri: uri);
  }

  final q = uri.queryParameters;
  final head = segments.first;
  final tail = segments.length > 1 ? segments[1] : null;

  switch (head) {
    case 's':
      // /s/:id short link — needs server resolution.
      if (tail == null || tail.isEmpty) break;
      return DeepLinkTarget._(kind: DeepLinkKind.shortLink, uri: uri, id: tail);

    case 'stay':
      // /stay/result?l=..&m=..&r=..&b=..&ci=..&co=..&ss=..
      if (tail != 'result') break;
      return DeepLinkTarget._(
        kind: DeepLinkKind.stay,
        uri: uri,
        region: q['r'],
        mode: q['m'],
        budget: q['b'],
        checkIn: q['ci'],
        checkOut: q['co'],
        stayStyle: q['ss'],
        landmarks: _parseLandmarks(q['l']),
      );

    case 'result':
      // /result?p=id1,id2&m=..&r=..&c=..&b=..&o=opt1,opt2
      return DeepLinkTarget._(
        kind: DeepLinkKind.meetup,
        uri: uri,
        region: q['r'],
        mode: q['m'],
        budget: q['b'],
        category: q['c'],
        stationIds: _csv(q['p']),
        options: _csv(q['o']),
      );

    case 'guide':
      if (tail == null || tail.isEmpty) break;
      return DeepLinkTarget._(kind: DeepLinkKind.guide, uri: uri, slug: tail);

    case 'spot':
      if (tail == null || tail.isEmpty) break;
      return DeepLinkTarget._(kind: DeepLinkKind.spot, uri: uri, slug: tail);

    case 'vote':
      if (tail == null || tail.isEmpty) break;
      return DeepLinkTarget._(kind: DeepLinkKind.vote, uri: uri, id: tail);
  }

  // Recognised as ours but not natively routable (station hub, itinerary, …).
  return DeepLinkTarget._(kind: DeepLinkKind.external, uri: uri);
}

/// Normalise path segments across https and the custom scheme, stripping a
/// leading locale segment. For `norigo://stay/result` the authority lands in
/// `uri.host`, so fold it back in unless it's the domain.
List<String> _pathSegments(Uri uri) {
  final raw = <String>[
    if (uri.scheme == 'norigo' &&
        uri.host.isNotEmpty &&
        !norigoHosts.contains(uri.host))
      uri.host,
    ...uri.pathSegments,
  ].where((s) => s.isNotEmpty).toList();

  if (raw.isNotEmpty && _localeSegmentsLower.contains(raw.first.toLowerCase())) {
    return raw.sublist(1);
  }
  return raw;
}

List<String> _csv(String? value) {
  if (value == null || value.isEmpty) return const [];
  return value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
}

/// Parse the stay `l` param: a JSON array of `{name, lat, lng}`. Returns an
/// empty list on any malformation so a bad link degrades to "no landmarks"
/// rather than throwing.
List<DeepLinkLandmark> _parseLandmarks(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    final result = <DeepLinkLandmark>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final name = item['name'];
      final lat = item['lat'];
      final lng = item['lng'];
      if (name is! String || lat is! num || lng is! num) continue;
      result.add(DeepLinkLandmark(
        name: name,
        lat: lat.toDouble(),
        lng: lng.toDouble(),
      ));
    }
    return result;
  } catch (_) {
    return const [];
  }
}
