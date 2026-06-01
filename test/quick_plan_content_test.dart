import 'package:flutter_test/flutter_test.dart';
import 'package:norigo_app/screens/home/widgets/quick_plan_cards.dart';

/// Validates the enriched starter-plan ("beginner intent") data: every plan
/// must carry complete decision copy (recommended base, best-for, why, caveat)
/// in all five languages, plus a valid 5-landmark set. Guards against a plan
/// shipping with a blank field that would render an empty card row.
void main() {
  const locales = ['ja', 'ko', 'en', 'zh', 'fr'];
  const requiredLabelKeys = [
    'title',
    'subtitle',
    'recommendedBase',
    'bestFor',
    'why1',
    'why2',
    'caveat',
  ];
  const validRegions = {'kanto', 'kansai', 'kyushu'};

  test('ships the full set of starter plans (web parity)', () {
    final ids = quickPlans.map((p) => p.id).toList();
    expect(ids, [
      'tokyo-classic',
      'tokyo-traditional',
      'tokyo-family',
      'osaka-gourmet',
      'kyoto-daytrip',
      'fukuoka-classic',
      'kyushu-onsen',
    ]);
  });

  group('every plan has complete decision copy in all 5 languages', () {
    for (final plan in quickPlans) {
      test('${plan.id} labels', () {
        expect(validRegions.contains(plan.region), isTrue,
            reason: '${plan.id} has invalid region ${plan.region}');
        for (final locale in locales) {
          final labels = plan.labels[locale];
          expect(labels, isNotNull, reason: '${plan.id} missing locale $locale');
          for (final key in requiredLabelKeys) {
            final value = labels![key];
            expect(value, isNotNull,
                reason: '${plan.id}/$locale missing "$key"');
            expect(value!.trim(), isNotEmpty,
                reason: '${plan.id}/$locale has blank "$key"');
          }
        }
      });
    }
  });

  group('every plan has a valid 5-landmark set', () {
    for (final plan in quickPlans) {
      test('${plan.id} landmarks', () {
        expect(plan.landmarks.length, 5,
            reason: '${plan.id} should have 5 landmarks');
        for (final lm in plan.landmarks) {
          expect(lm['slug'], isA<String>());
          expect((lm['slug'] as String).isNotEmpty, isTrue);
          expect(lm['name'], isA<String>());
          expect(lm['nameEn'], isA<String>());
          expect(lm['region'], plan.region);
          final lat = lm['lat'] as double;
          final lng = lm['lng'] as double;
          // Japan bounding box — catches swapped/zeroed coordinates.
          expect(lat, inInclusiveRange(24.0, 46.0),
              reason: '${plan.id} ${lm['slug']} lat out of range');
          expect(lng, inInclusiveRange(122.0, 146.0),
              reason: '${plan.id} ${lm['slug']} lng out of range');
        }
      });
    }
  });

  test('every plan points at a landmarks webp image', () {
    for (final plan in quickPlans) {
      expect(plan.image, startsWith('/images/landmarks/'),
          reason: '${plan.id} image path');
      expect(plan.image, endsWith('.webp'), reason: '${plan.id} image type');
    }
  });
}
