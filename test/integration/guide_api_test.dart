import 'package:flutter_test/flutter_test.dart';
import 'package:norigo_app/services/api_client.dart';

/// Tests for Guide API — verifies list and detail endpoints.
void main() {
  late ApiClient api;

  setUp(() {
    api = ApiClient();
  });

  group('Guide List API', () {
    test('returns guides for kanto region', () async {
      final guides = await api.getGuides(locale: 'ko', region: 'kanto');

      expect(guides, isNotEmpty);
      expect(guides.length, greaterThan(5));

      final first = guides.first;
      expect(first['slug'], isNotNull);
      expect(first['title'], isNotNull);
      expect(first['title'], isNotEmpty);
      expect(first['heroImage'], contains('norigo.app'));
      print('✓ Kanto guides: ${guides.length} (first: ${first['title']})');
    });

    test('returns guides for kansai region', () async {
      final guides = await api.getGuides(locale: 'ja', region: 'kansai');

      expect(guides, isNotEmpty);
      final first = guides.first;
      expect(first['region'], 'kansai');
      print('✓ Kansai guides: ${guides.length}');
    });

    test('returns guides for seoul region', () async {
      final guides = await api.getGuides(locale: 'ko', region: 'seoul');

      expect(guides, isNotEmpty);
      print('✓ Seoul guides: ${guides.length}');
    });

    test('returns all guides without region filter', () async {
      final all = await api.getGuides(locale: 'en');
      final kanto = await api.getGuides(locale: 'en', region: 'kanto');

      expect(all.length, greaterThanOrEqualTo(kanto.length));
      print('✓ All guides: ${all.length}, Kanto only: ${kanto.length}');
    });

    test('locale affects guide titles', () async {
      final ko = await api.getGuides(locale: 'ko', region: 'kanto');
      final ja = await api.getGuides(locale: 'ja', region: 'kanto');

      // Same slug but different titles
      final koFirst = ko.firstWhere((g) => g['slug'] == 'akihabara-otaku');
      final jaFirst = ja.firstWhere((g) => g['slug'] == 'akihabara-otaku');
      expect(koFirst['title'], isNot(equals(jaFirst['title'])));
      print('✓ ko: ${koFirst['title']}');
      print('  ja: ${jaFirst['title']}');
    });
  });

  group('Guide Detail API', () {
    test('returns full guide content', () async {
      final data = await api.getGuideDetail('akihabara-otaku', locale: 'ko');

      expect(data['slug'], 'akihabara-otaku');
      expect(data['title'], isNotEmpty);
      expect(data['contentMarkdown'], isNotNull);
      expect((data['contentMarkdown'] as String).length, greaterThan(100));
      expect(data['heroImage'], contains('norigo.app'));
      print('✓ Guide detail: ${data['title']}, markdown: ${(data['contentMarkdown'] as String).length} chars');
    });

    test('contains structured spots data', () async {
      final data = await api.getGuideDetail('akihabara-otaku', locale: 'ko');
      final spots = data['spots'] as List<dynamic>;

      expect(spots, isNotEmpty);
      final first = spots.first as Map<String, dynamic>;
      expect(first['name'], isNotEmpty);
      expect(first['slug'], isNotEmpty);
      print('✓ Spots: ${spots.length} (first: ${first['name']})');
    });

    test('contains FAQ data', () async {
      final data = await api.getGuideDetail('akihabara-otaku', locale: 'ko');
      final faq = data['faq'] as List<dynamic>;

      expect(faq, isNotEmpty);
      final first = faq.first as Map<String, dynamic>;
      expect(first['question'], isNotEmpty);
      expect(first['answer'], isNotEmpty);
      print('✓ FAQ: ${faq.length} (first: ${first['question']})');
    });

    test('contains TOC', () async {
      final data = await api.getGuideDetail('akihabara-otaku', locale: 'ko');
      final toc = data['toc'] as List<dynamic>;

      expect(toc, isNotEmpty);
      print('✓ TOC: ${toc.length} items');
    });

    test('different locales return different content', () async {
      final ko = await api.getGuideDetail('akihabara-otaku', locale: 'ko');
      final ja = await api.getGuideDetail('akihabara-otaku', locale: 'ja');

      expect(ko['title'], isNot(equals(ja['title'])));
      expect(ko['contentMarkdown'], isNot(equals(ja['contentMarkdown'])));
      print('✓ ko title: ${ko['title']}');
      print('  ja title: ${ja['title']}');
    });
  });
}
