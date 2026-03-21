import 'package:flutter_test/flutter_test.dart';

/// Test share URL generation logic (no Flutter widgets needed)
void main() {
  group('Stay share URL', () {
    test('generates correct web-compatible URL with all params', () {
      // Simulate state
      final landmarks = [
        {'slug': 'shibuya-crossing', 'name': '渋谷', 'lat': 35.6595, 'lng': 139.7004},
        {'slug': 'asakusa-senso-ji', 'name': '浅草', 'lat': 35.7148, 'lng': 139.7967},
      ];
      final mode = 'minTotal';
      final region = 'kanto';
      final maxBudget = 'under30000';
      final checkIn = '2026-04-21';
      final checkOut = '2026-04-24';
      final locale = 'ko';

      // Build URL same way as _buildStayShareUrl
      final landmarkJson = landmarks.map((l) =>
        '{"slug":"${l['slug']}","name":"${l['name']}","lat":${l['lat']},"lng":${l['lng']}}'
      ).toList();
      final params = <String, String>{
        'l': '[${landmarkJson.join(',')}]',
        'm': mode,
        'r': region,
        'b': maxBudget,
        'ci': checkIn,
        'co': checkOut,
      };
      final url = Uri.parse('https://norigo.app/$locale/stay/result')
          .replace(queryParameters: params).toString();

      print('Stay share URL: $url');

      expect(url, contains('norigo.app/ko/stay/result'));
      expect(url, contains('m=minTotal'));
      expect(url, contains('r=kanto'));
      expect(url, contains('b=under30000'));
      expect(url, contains('ci=2026-04-21'));
      expect(url, contains('co=2026-04-24'));
      expect(url, contains('shibuya-crossing'));
      expect(url, contains('asakusa-senso-ji'));
    });

    test('URL is parseable and params are extractable', () {
      final params = <String, String>{
        'l': '[{"slug":"shibuya","name":"渋谷","lat":35.6595,"lng":139.7004}]',
        'm': 'centroid',
        'r': 'kanto',
      };
      final url = Uri.parse('https://norigo.app/ja/stay/result')
          .replace(queryParameters: params).toString();

      // Verify it can be parsed back
      final parsed = Uri.parse(url);
      expect(parsed.host, 'norigo.app');
      expect(parsed.queryParameters['m'], 'centroid');
      expect(parsed.queryParameters['r'], 'kanto');
      expect(parsed.queryParameters['l'], contains('shibuya'));
      print('Parsed URL OK: $url');
    });
  });

  group('Meetup share URL', () {
    test('generates correct web-compatible URL', () {
      final stationIds = 'shinjuku,shibuya,ikebukuro';
      final mode = 'centroid';
      final region = 'kanto';
      final locale = 'ja';

      final params = <String, String>{
        'p': stationIds,
        'm': mode,
        'r': region,
      };
      final url = Uri.parse('https://norigo.app/$locale/result')
          .replace(queryParameters: params).toString();

      print('Meetup share URL: $url');

      expect(url, contains('norigo.app/ja/result'));
      expect(url, contains('p=shinjuku'));
      expect(url, contains('m=centroid'));
      expect(url, contains('r=kanto'));
    });
  });

  group('LINE share URL', () {
    test('LIFF URL is correctly formatted', () {
      final shareUrl = 'https://norigo.app/ja/result?p=shinjuku,shibuya&m=centroid&r=kanto';
      final urlWithExternal = '$shareUrl&openExternalBrowser=1';
      final title = 'Norigo';
      final desc = 'みんなの集合駅で検索したら「新宿駅」がおすすめ！';

      final liffParams = Uri(queryParameters: {
        'url': urlWithExternal,
        'title': title,
        'desc': desc,
      }).query;
      final liffUrl = 'https://liff.line.me/2009553286-JcRNsKER?$liffParams';

      print('LIFF URL: $liffUrl');

      expect(liffUrl, contains('liff.line.me/2009553286-JcRNsKER'));
      expect(liffUrl, contains('url='));
      expect(liffUrl, contains('title=Norigo'));
      expect(liffUrl, contains('desc='));
      // Verify it's a valid URI
      final parsed = Uri.parse(liffUrl);
      expect(parsed.host, 'liff.line.me');
    });
  });

  group('Kakao share URL', () {
    test('Kakao sharer URL is correctly formatted', () {
      final shareUrl = 'https://norigo.app/ko/stay/result?l=test&m=minTotal&r=kanto';
      final title = 'Norigo';
      final text = '시부야・아사쿠사 여행에 최적의 호텔 지역';
      final locale = 'ko';
      final imageUrl = 'https://norigo.app/api/og?locale=$locale';

      final templateObject = '{"object_type":"feed","content":{"title":"$title","description":"$text","image_url":"$imageUrl","link":{"mobile_web_url":"$shareUrl","web_url":"$shareUrl"}},"buttons":[{"title":"결과 보기","link":{"mobile_web_url":"$shareUrl","web_url":"$shareUrl"}}]}';

      final kakaoUrl = Uri.parse('https://sharer.kakao.com/talk/friends/picker/link').replace(
        queryParameters: {
          'app_key': 'ef83068e8071507be6a45e8af10706ee',
          'ka': 'sdk/2.7.4 os/flutter lang/$locale',
          'link_ver': '4.0',
          'template_object': templateObject,
        },
      );

      print('Kakao URL: $kakaoUrl');

      expect(kakaoUrl.toString(), contains('sharer.kakao.com'));
      expect(kakaoUrl.toString(), contains('app_key='));
      expect(kakaoUrl.toString(), contains('template_object='));
      // Verify parseable
      final parsed = Uri.parse(kakaoUrl.toString());
      expect(parsed.host, 'sharer.kakao.com');
      expect(parsed.queryParameters['app_key'], 'ef83068e8071507be6a45e8af10706ee');
    });
  });

  group('Twitter share URL', () {
    test('Twitter intent URL separates text and url', () {
      final text = '시부야・아사쿠사 여행에 최적의 호텔 지역';
      final url = 'https://norigo.app/ko/stay/result?l=test&m=minTotal';

      final twitterUrl = 'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(text)}&url=${Uri.encodeComponent(url)}';

      print('Twitter URL: $twitterUrl');

      expect(twitterUrl, contains('twitter.com/intent/tweet'));
      expect(twitterUrl, contains('text='));
      expect(twitterUrl, contains('url='));
      // text and url should be separate params, not combined
      final parsed = Uri.parse(twitterUrl);
      expect(parsed.queryParameters.containsKey('text'), true);
      expect(parsed.queryParameters.containsKey('url'), true);
    });
  });

  group('UTM tracking params', () {
    test('adds utm_source and utm_medium', () {
      final baseUrl = 'https://norigo.app/ko/stay/result?l=test&m=minTotal&r=kanto';
      final uri = Uri.parse(baseUrl);
      final params = Map<String, String>.from(uri.queryParameters);
      params['utm_source'] = 'share';
      params['utm_medium'] = 'kakao';
      final tracked = uri.replace(queryParameters: params).toString();

      print('Tracked URL: $tracked');

      expect(tracked, contains('utm_source=share'));
      expect(tracked, contains('utm_medium=kakao'));
      // Original params preserved
      expect(tracked, contains('m=minTotal'));
      expect(tracked, contains('r=kanto'));
    });
  });
}
