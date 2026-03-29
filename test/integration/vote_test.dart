import 'package:flutter_test/flutter_test.dart';
import 'package:norigo_app/services/api_client.dart';
import 'package:norigo_app/models/meetup_result.dart';

/// Tests for vote API — derived from web app's vote implementation.
/// Tests create a poll, fetch it, vote, and verify state changes.
void main() {
  late ApiClient api;

  setUp(() {
    api = ApiClient();
  });

  group('Vote API', () {
    test('create poll returns pollId', () async {
      final venues = [
        Venue.fromJson({
          'name': 'テスト居酒屋A',
          'genre': '居酒屋',
          'budget': '3000円〜',
          'url': 'https://example.com/a',
        }),
        Venue.fromJson({
          'name': 'テスト居酒屋B',
          'genre': 'イタリアン',
          'budget': '4000円〜',
          'url': 'https://example.com/b',
        }),
      ];

      final pollId = await api.createVotePoll(
        stationName: '新宿',
        stationId: 'shinjuku',
        venues: venues,
      );

      expect(pollId, isNotNull);
      expect(pollId, isNotEmpty);
      print('✓ Created poll: $pollId');
    });

    test('get poll returns poll data with venues', () async {
      // Create poll first
      final venues = [
        Venue.fromJson({'name': 'Shop A', 'url': 'https://example.com/a'}),
        Venue.fromJson({'name': 'Shop B', 'url': 'https://example.com/b'}),
      ];
      final pollId = await api.createVotePoll(
        stationName: '渋谷',
        stationId: 'shibuya',
        venues: venues,
      );
      expect(pollId, isNotNull);

      // Fetch poll
      final data = await api.getVotePoll(pollId!, voterId: 'test-voter-1');
      final poll = data['poll'] as Map<String, dynamic>;

      expect(poll['stationName'], '渋谷');
      expect(poll['venues'], isNotNull);
      expect((poll['venues'] as List).length, 2);
      expect(data['totalVoters'], 0);
      expect(data['myVenueIds'], isEmpty);
      print('✓ Fetched poll: stationName=${poll['stationName']}, venues=${(poll['venues'] as List).length}');
    });

    test('toggle vote adds and removes vote', () async {
      // Create poll
      final venues = [
        Venue.fromJson({'name': 'Vote Test Shop', 'url': 'https://example.com/vote'}),
      ];
      final pollId = await api.createVotePoll(
        stationName: '池袋',
        stationId: 'ikebukuro',
        venues: venues,
      );
      expect(pollId, isNotNull);

      // Get venue ID from poll
      final pollData = await api.getVotePoll(pollId!);
      final venueList = pollData['poll']['venues'] as List;
      final venueId = venueList[0]['id'].toString();

      // Vote (add)
      final action1 = await api.toggleVote(
        pollId: pollId,
        venueId: venueId,
        voterId: 'test-voter-2',
      );
      expect(action1, 'added');

      // Verify vote was added
      final after1 = await api.getVotePoll(pollId, voterId: 'test-voter-2');
      final counts1 = (after1['voteCounts'] as Map<String, dynamic>);
      expect(counts1[venueId], 1);
      expect(after1['totalVoters'], 1);
      expect((after1['myVenueIds'] as List), contains(venueId));

      // Vote again (remove — toggle)
      final action2 = await api.toggleVote(
        pollId: pollId,
        venueId: venueId,
        voterId: 'test-voter-2',
      );
      expect(action2, 'removed');

      // Verify vote was removed
      final after2 = await api.getVotePoll(pollId, voterId: 'test-voter-2');
      expect(after2['totalVoters'], 0);
      print('✓ Vote toggle works: added → removed');
    });

    test('multiple voters tracked separately', () async {
      final venues = [
        Venue.fromJson({'name': 'Multi Vote Shop', 'url': 'https://example.com/multi'}),
      ];
      final pollId = await api.createVotePoll(
        stationName: '東京',
        stationId: 'tokyo',
        venues: venues,
      );
      expect(pollId, isNotNull);

      final pollData = await api.getVotePoll(pollId!);
      final venueId = (pollData['poll']['venues'] as List)[0]['id'].toString();

      // Two different voters vote
      await api.toggleVote(pollId: pollId, venueId: venueId, voterId: 'voter-a');
      await api.toggleVote(pollId: pollId, venueId: venueId, voterId: 'voter-b');

      // Check counts
      final data = await api.getVotePoll(pollId, voterId: 'voter-a');
      expect(data['totalVoters'], 2);
      expect((data['voteCounts'] as Map)[venueId], 2);
      expect((data['myVenueIds'] as List), contains(venueId));

      // voter-b's view
      final dataB = await api.getVotePoll(pollId, voterId: 'voter-b');
      expect((dataB['myVenueIds'] as List), contains(venueId));

      // voter-c hasn't voted
      final dataC = await api.getVotePoll(pollId, voterId: 'voter-c');
      expect((dataC['myVenueIds'] as List), isEmpty);
      print('✓ Multiple voters tracked: 2 votes, voter-a/b voted, voter-c not');
    });
  });
}
