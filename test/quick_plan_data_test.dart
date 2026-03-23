import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Tests for quick plan data consistency and line colors
void main() {
  group('Quick plan landmarks count', () {
    test('all kanto plans have 5 landmarks', () {
      // Verify stay_search_screen and quick_plan_cards both have 5
      final stayFile = File('lib/screens/stay/stay_search_screen.dart').readAsStringSync();
      final homeFile = File('lib/screens/home/widgets/quick_plan_cards.dart').readAsStringSync();

      // Count landmarks in kanto plans
      final stayKantoMatches = RegExp(r"'kanto'.*?'landmarks'.*?\[([^\]]*)\]", dotAll: true).firstMatch(stayFile);
      final homeKantoMatches = RegExp(r"id: 'tokyo-classic'.*?landmarks: \[(.*?)\]", dotAll: true).firstMatch(homeFile);

      if (stayKantoMatches != null) {
        final count = "'lat':".allMatches(stayKantoMatches.group(1)!).length;
        expect(count, 5, reason: 'stay_search kanto first plan should have 5 landmarks');
      }
      if (homeKantoMatches != null) {
        final count = "'slug':".allMatches(homeKantoMatches.group(1)!).length;
        expect(count, 5, reason: 'quick_plan_cards tokyo-classic should have 5 landmarks');
      }
    });

    test('all kansai plans have 5 landmarks in quick_plan_cards', () {
      final homeFile = File('lib/screens/home/widgets/quick_plan_cards.dart').readAsStringSync();

      // osaka-gourmet
      final osakaMatch = RegExp(r"id: 'osaka-gourmet'.*?landmarks: \[(.*?)\]", dotAll: true).firstMatch(homeFile);
      if (osakaMatch != null) {
        final count = "'slug':".allMatches(osakaMatch.group(1)!).length;
        expect(count, 5, reason: 'osaka-gourmet should have 5 landmarks');
      }

      // kyoto-daytrip
      final kyotoMatch = RegExp(r"id: 'kyoto-daytrip'.*?landmarks: \[(.*?)\]", dotAll: true).firstMatch(homeFile);
      if (kyotoMatch != null) {
        final count = "'slug':".allMatches(kyotoMatch.group(1)!).length;
        expect(count, 5, reason: 'kyoto-daytrip should have 5 landmarks');
      }
    });
  });

  group('Line colors data', () {
    late Map<String, dynamic> colors;

    setUpAll(() {
      final raw = File('assets/data/line-colors.json').readAsStringSync();
      colors = jsonDecode(raw) as Map<String, dynamic>;
    });

    test('has 300+ line colors', () {
      expect(colors.length, greaterThan(300));
      print('✓ Line colors: ${colors.length} entries');
    });

    test('major Tokyo lines have correct colors', () {
      expect(colors['山手線'], '#9ACD32');
      expect(colors['中央線'], '#FF4500');
      expect(colors['丸ノ内線'], '#F62E36');
      expect(colors['銀座線'], '#FF9500');
      expect(colors['半蔵門線'], '#8F76D6');
      expect(colors['井の頭線'], '#BB33FF');
      expect(colors['大江戸線'], '#CE004F');
      print('✓ Tokyo line colors verified');
    });

    test('Korean metro lines have colors', () {
      expect(colors['1호선'], '#0052A4');
      expect(colors['2호선'], '#00A84D');
      expect(colors['부산1호선'], '#F06A00');
      print('✓ Korean line colors verified');
    });

    test('Osaka metro lines have colors', () {
      expect(colors['御堂筋線'], '#C9242B');
      expect(colors['堺筋線'], '#8D6B22');
      print('✓ Osaka line colors verified');
    });
  });

  group('Budget setting', () {
    test('home screen quick plan uses under50000', () {
      final homeFile = File('lib/screens/home/home_screen.dart').readAsStringSync();
      expect(homeFile.contains("setBudget('under50000')"), true,
        reason: 'Quick plan should set budget to under50000 (matching web)');
    });
  });
}
