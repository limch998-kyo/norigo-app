import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:norigo_app/services/deep_link_parser.dart';

DeepLinkTarget? parse(String url) => parseNorigoUri(Uri.parse(url));

void main() {
  group('parseNorigoUri — non-norigo links', () {
    test('returns null for unrelated https hosts', () {
      expect(parse('https://example.com/stay/result'), isNull);
      expect(parse('https://google.com/'), isNull);
    });

    test('returns null for unrelated custom schemes', () {
      expect(parse('kakao123://oauth'), isNull);
    });
  });

  group('parseNorigoUri — host + scheme handling', () {
    test('accepts norigo.app and www.norigo.app over https', () {
      expect(parse('https://norigo.app/vote/abc')!.kind, DeepLinkKind.vote);
      expect(parse('https://www.norigo.app/vote/abc')!.kind, DeepLinkKind.vote);
    });

    test('accepts the norigo:// custom scheme (authority-as-host form)', () {
      final t = parse('norigo://vote/abc');
      expect(t!.kind, DeepLinkKind.vote);
      expect(t.id, 'abc');
    });

    test('accepts the norigo:// custom scheme (hostless form)', () {
      final t = parse('norigo:///vote/abc');
      expect(t!.kind, DeepLinkKind.vote);
      expect(t.id, 'abc');
    });

    test('accepts norigo://norigo.app/... domain form', () {
      final t = parse('norigo://norigo.app/guide/tokyo-first');
      expect(t!.kind, DeepLinkKind.guide);
      expect(t.slug, 'tokyo-first');
    });

    test('strips a leading locale segment', () {
      expect(parse('https://norigo.app/ja/vote/abc')!.kind, DeepLinkKind.vote);
      expect(parse('https://norigo.app/ko/guide/x')!.slug, 'x');
      expect(parse('https://norigo.app/fr/spot/y')!.slug, 'y');
    });

    test('strips the zh-TW locale segment (web routing.ts includes zh-TW)', () {
      expect(
        parse('https://norigo.app/zh-TW/vote/abc')!.kind,
        DeepLinkKind.vote,
      );
      expect(
        parse('https://norigo.app/zh-TW/stay/result?r=kanto')!.kind,
        DeepLinkKind.stay,
      );
      expect(
        parse('https://norigo.app/zh-TW/result?p=a,b')!.kind,
        DeepLinkKind.meetup,
      );
    });

    test('strips locale segments case-insensitively — norigo:// puts the '
        'locale in the authority, which Dart lowercases (zh-TW → zh-tw)', () {
      expect(parse('norigo://zh-TW/vote/abc')!.kind, DeepLinkKind.vote);
      expect(parse('norigo://ja/guide/x')!.slug, 'x');
      expect(parse('https://norigo.app/ZH-TW/vote/abc')!.kind,
          DeepLinkKind.vote);
    });

    test('bare home link resolves to external (nothing to route)', () {
      expect(parse('https://norigo.app/')!.kind, DeepLinkKind.external);
      expect(parse('https://norigo.app/ja')!.kind, DeepLinkKind.external);
    });
  });

  group('parseNorigoUri — content routes', () {
    test('guide slug', () {
      final t = parse('https://norigo.app/guide/shibuya-night');
      expect(t!.kind, DeepLinkKind.guide);
      expect(t.slug, 'shibuya-night');
    });

    test('spot slug', () {
      final t = parse('https://norigo.app/spot/sensoji-temple');
      expect(t!.kind, DeepLinkKind.spot);
      expect(t.slug, 'sensoji-temple');
    });

    test('vote id', () {
      final t = parse('https://norigo.app/vote/WvIR-O18');
      expect(t!.kind, DeepLinkKind.vote);
      expect(t.id, 'WvIR-O18');
    });

    test('guide/spot/vote without a slug fall back to external', () {
      expect(parse('https://norigo.app/guide')!.kind, DeepLinkKind.external);
      expect(parse('https://norigo.app/spot/')!.kind, DeepLinkKind.external);
      expect(parse('https://norigo.app/vote')!.kind, DeepLinkKind.external);
    });
  });

  group('parseNorigoUri — short link', () {
    test('/s/:id resolves to shortLink kind with id', () {
      final t = parse('https://norigo.app/s/WvIR-O18');
      expect(t!.kind, DeepLinkKind.shortLink);
      expect(t.id, 'WvIR-O18');
    });
  });

  group('parseNorigoUri — stay search restore', () {
    test('parses landmarks JSON and all params', () {
      final l = jsonEncode([
        {'name': '渋谷', 'lat': 35.6595, 'lng': 139.7004},
        {'name': '新宿', 'lat': 35.6852, 'lng': 139.71},
      ]);
      final uri = Uri.parse('https://norigo.app/stay/result').replace(
        queryParameters: {
          'l': l,
          'm': 'centroid',
          'r': 'kanto',
          'b': '10000-30000',
          'ci': '2026-07-01',
          'co': '2026-07-04',
          'ss': 'single',
        },
      );
      final t = parseNorigoUri(uri)!;
      expect(t.kind, DeepLinkKind.stay);
      expect(t.region, 'kanto');
      expect(t.mode, 'centroid');
      expect(t.budget, '10000-30000');
      expect(t.checkIn, '2026-07-01');
      expect(t.checkOut, '2026-07-04');
      expect(t.stayStyle, 'single');
      expect(t.landmarks.length, 2);
      expect(t.landmarks.first.name, '渋谷');
      expect(t.landmarks.first.lat, closeTo(35.6595, 1e-9));
      expect(t.landmarks[1].lng, closeTo(139.71, 1e-9));
    });

    test('locale-prefixed stay link still parses', () {
      final l = jsonEncode([
        {'name': 'A', 'lat': 1.0, 'lng': 2.0},
      ]);
      final uri = Uri.parse('https://norigo.app/ja/stay/result')
          .replace(queryParameters: {'l': l, 'r': 'kansai', 'm': 'minTotal'});
      final t = parseNorigoUri(uri)!;
      expect(t.kind, DeepLinkKind.stay);
      expect(t.region, 'kansai');
      expect(t.landmarks.single.name, 'A');
    });

    test('malformed landmark JSON degrades to empty list, not a throw', () {
      final uri = Uri.parse('https://norigo.app/stay/result')
          .replace(queryParameters: {'l': 'not json', 'r': 'kanto'});
      final t = parseNorigoUri(uri)!;
      expect(t.kind, DeepLinkKind.stay);
      expect(t.landmarks, isEmpty);
      expect(t.region, 'kanto');
    });

    test('drops landmark entries with missing/invalid fields', () {
      final l = jsonEncode([
        {'name': 'ok', 'lat': 1, 'lng': 2},
        {'name': 'no-coords'},
        {'lat': 3, 'lng': 4},
        {'name': 'bad-lat', 'lat': 'x', 'lng': 4},
      ]);
      final uri = Uri.parse('https://norigo.app/stay/result')
          .replace(queryParameters: {'l': l});
      final t = parseNorigoUri(uri)!;
      expect(t.landmarks.length, 1);
      expect(t.landmarks.single.name, 'ok');
    });

    test('/stay without /result falls back to external', () {
      expect(parse('https://norigo.app/stay')!.kind, DeepLinkKind.external);
      expect(parse('https://norigo.app/stay/search')!.kind, DeepLinkKind.external);
    });
  });

  group('parseNorigoUri — meetup search restore', () {
    test('parses station ids, options and params', () {
      final uri = Uri.parse('https://norigo.app/result').replace(
        queryParameters: {
          'p': 'shinjuku,shibuya,tokyo',
          'm': 'centroid',
          'r': 'kanto',
          'c': 'izakaya',
          'o': 'wifi,parking',
        },
      );
      final t = parseNorigoUri(uri)!;
      expect(t.kind, DeepLinkKind.meetup);
      expect(t.stationIds, ['shinjuku', 'shibuya', 'tokyo']);
      expect(t.options, ['wifi', 'parking']);
      expect(t.mode, 'centroid');
      expect(t.region, 'kanto');
      expect(t.category, 'izakaya');
    });

    test('empty station list when p is absent', () {
      final t = parse('https://norigo.app/result?r=kanto')!;
      expect(t.kind, DeepLinkKind.meetup);
      expect(t.stationIds, isEmpty);
      expect(t.options, isEmpty);
    });
  });

  group('parseNorigoUri — external fallback', () {
    test('station hub and itinerary are recognised but external', () {
      expect(parse('https://norigo.app/station/shinjuku')!.kind,
          DeepLinkKind.external);
      expect(parse('https://norigo.app/trip/itinerary?l=[]')!.kind,
          DeepLinkKind.external);
    });

    test('external target keeps the original uri', () {
      final t = parse('https://norigo.app/station/shinjuku')!;
      expect(t.uri.toString(), 'https://norigo.app/station/shinjuku');
    });
  });
}
